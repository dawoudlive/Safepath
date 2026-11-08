import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../i18n.dart';
import '../services/tile_cache.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  final TileProvider _provider = createTileProvider();
  LatLng? _me;
  String? _error;

  // Default view: Doha. Replaced by GPS position when available.
  static const LatLng _doha = LatLng(25.2854, 51.5310);

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _error = tr('Location permission denied',
            'تم رفض إذن الموقع'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _me = p;
        _error = null;
      });
      _controller.move(p, 15);
    } catch (e) {
      setState(() => _error = tr('Could not get GPS position',
          'تعذر تحديد الموقع'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Maps', 'الخرائط'))),
      floatingActionButton: FloatingActionButton(
        onPressed: _locate,
        child: const Icon(Icons.my_location),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(8),
            child: Text(
              _error ??
                  (_me == null
                      ? tr('Looking for GPS...', 'جاري البحث عن الموقع...')
                      : '${_me!.latitude.toStringAsFixed(5)}, '
                          '${_me!.longitude.toStringAsFixed(5)}'),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _doha,
                initialZoom: 12,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safepath.app',
                  tileProvider: _provider,
                ),
                if (_me != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _me!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
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
