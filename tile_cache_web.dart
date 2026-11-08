import 'package:flutter_map/flutter_map.dart';

/// On the web, tiles are saved by the browser and by our service worker
/// (web/sw.js), so nothing to set up here.
Future<void> initTileCache() async {}

TileProvider createTileProvider() => NetworkTileProvider();
