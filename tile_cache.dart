// Picks the right map-tile cache for the platform:
//  - Android / iPhone app: saves tiles as files on the phone (tile_cache_io.dart)
//  - Web: the browser + service worker keep tiles (tile_cache_web.dart)
//
// Both provide:
//   Future<void> initTileCache()
//   TileProvider createTileProvider()
export 'tile_cache_web.dart' if (dart.library.io) 'tile_cache_io.dart';
