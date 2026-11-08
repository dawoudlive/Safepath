import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../i18n.dart';
import '../services/tile_cache.dart';
import '../theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  final TileProvider _provider = createTileProvider();
  StreamSubscription<Position>? _sub;
  LatLng? _me;
  double _accuracy = 0;
  String? _error;
  bool _follow = true;
  bool _centeredOnce = false;

  // Default view: Doha. Replaced by GPS position when available.
  static const LatLng _doha = LatLng(25.2854, 51.5310);

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() =>
            _error = tr('Location permission denied', 'تم رفض إذن الموقع'));
        return;
      }
      await _sub?.cancel();
      // Live updates: a new position arrives whenever you move about 5 metres.
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) {
          final p = LatLng(pos.latitude, pos.longitude);
          if (!mounted) return;
          setState(() {
            _me = p;
            _accuracy = pos.accuracy;
            _error = null;
          });
          if (_follow || !_centeredOnce) {
            _centeredOnce = true;
            try {
              final z = _centeredOnceZoom();
              _controller.move(p, z);
            } catch (_) {}
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _error =
                tr('Could not get GPS position', 'تعذر تحديد الموقع'));
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = tr('Could not get GPS position', 'تعذر تحديد الموقع'));
      }
    }
  }

  double _centeredOnceZoom() {
    try {
      final z = _controller.camera.zoom;
      return z < 14 ? 16 : z;
    } catch (_) {
      return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Maps', 'الخرائط')),
        backgroundColor: Palette.maps.first,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _follow ? Palette.maps.first : cs.surfaceContainerHigh,
        foregroundColor: _follow ? Colors.white : cs.onSurface,
        onPressed: () {
          setState(() => _follow = true);
          if (_me != null) _controller.move(_me!, _centeredOnceZoom());
          if (_sub == null) _startTracking();
        },
        icon: Icon(_follow ? Icons.gps_fixed : Icons.gps_not_fixed),
        label: Text(_follow ? tr('Following you', 'يتتبع موقعك')
            : tr('Follow me', 'تتبّعني')),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _error != null ? Colors.orange.shade100 : Colors.blue.shade50,
            padding: const EdgeInsets.all(8),
            child: Text(
              _error ??
                  (_me == null
                      ? tr('Looking for GPS...', 'جاري البحث عن الموقع...')
                      : '${_me!.latitude.toStringAsFixed(5)}, '
                          '${_me!.longitude.toStringAsFixed(5)}'
                          '   ±${_accuracy.toStringAsFixed(0)} m'),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _doha,
                initialZoom: 12,
                maxZoom: 18,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safepath.app',
                  tileProvider: _provider,
                ),
                if (_me != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _me!,
                        radius: _accuracy < 5 ? 5 : _accuracy,
                        useRadiusInMeter: true,
                        color: const Color(0x332979FF),
                        borderColor: const Color(0xFF2979FF),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                if (_me != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _me!,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
