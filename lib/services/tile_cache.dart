import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Saves every map tile you view to the phone, so areas you have looked at
/// still show when there is no internet.
///
/// NOTE: this is browse-caching only. Do not bulk-download tiles from
/// tile.openstreetmap.org (against their usage policy). A proper
/// "download a whole region" feature needs our own tile pack (MBTiles) later.
class TileCache {
  static late Directory dir;

  static Future<void> init() async {
    final base = await getApplicationSupportDirectory();
    dir = Directory('${base.path}/tiles');
    await dir.create(recursive: true);
  }
}

class CachedTileProvider extends TileProvider {
  CachedTileProvider() : super();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final file = File(
      '${TileCache.dir.path}/${coordinates.z}_${coordinates.x}_${coordinates.y}.png',
    );
    return _CachedTileImage(url, file);
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  _CachedTileImage(this.url, this.file);

  final String url;
  final File file;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_CachedTileImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      final r = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SafePathApp/0.1 (offline emergency app)'},
      );
      if (r.statusCode != 200) {
        throw Exception('Tile not available offline');
      }
      bytes = r.bodyBytes;
      try {
        await file.writeAsBytes(bytes);
      } catch (_) {}
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
