import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// Works out which country a GPS position is in, fully offline, using
/// simplified country borders bundled in the app, and looks up that
/// country's emergency numbers.
class CountryService {
  static List<dynamic>? _borders;
  static Map<String, dynamic>? _numbers;

  static Future<void> _load() async {
    if (_borders != null) return;
    _borders =
        jsonDecode(await rootBundle.loadString('assets/data/borders.json'))
            as List<dynamic>;
    final e = jsonDecode(await rootBundle.loadString('assets/data/emergency.json'))
        as Map<String, dynamic>;
    _numbers = e['numbers'] as Map<String, dynamic>;
  }

  /// All countries (code, English name), sorted by name. For the manual picker.
  static Future<List<MapEntry<String, String>>> allCountries() async {
    await _load();
    final seen = <String, String>{};
    for (final f in _borders!) {
      final m = f as Map;
      seen[m['c'].toString()] = m['n'].toString();
    }
    final list = seen.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  static Future<String> nameOf(String code) async {
    await _load();
    for (final f in _borders!) {
      final m = f as Map;
      if (m['c'] == code) return m['n'].toString();
    }
    return code;
  }

  /// ISO country code for a position, or null if far from any land (open sea).
  static Future<String?> codeFor(double lat, double lon) async {
    await _load();
    String? best;
    var bestArea = double.infinity;
    for (final f in _borders!) {
      final m = f as Map;
      for (final r in (m['r'] as List)) {
        final ring = (r as List).cast<num>();
        if (_inside(lon, lat, ring)) {
          final a = _bboxArea(ring);
          // Smallest containing shape wins (handles Lesotho inside South Africa)
          if (a < bestArea) {
            bestArea = a;
            best = m['c'].toString();
          }
        }
      }
    }
    if (best != null) return best;

    // Coastal points can fall just outside the simplified borders:
    // take the nearest border if it is within about 110 km.
    final k = math.cos(lat * math.pi / 180);
    var bestD = double.infinity;
    String? nearest;
    for (final f in _borders!) {
      final m = f as Map;
      for (final r in (m['r'] as List)) {
        final ring = (r as List).cast<num>();
        final n = ring.length ~/ 2;
        for (var i = 0; i < n - 1; i++) {
          final d = _segDist(lon, lat, ring[2 * i].toDouble(),
              ring[2 * i + 1].toDouble(), ring[2 * i + 2].toDouble(),
              ring[2 * i + 3].toDouble(), k);
          if (d < bestD) {
            bestD = d;
            nearest = m['c'].toString();
          }
        }
      }
    }
    return bestD < 1.0 ? nearest : null;
  }

  /// {'a': ambulance, 'p': police, 'f': fire}. Values can be null.
  static Future<Map<String, String?>> numbersFor(String code) async {
    await _load();
    final m = _numbers![code] as Map?;
    if (m == null) return {'a': null, 'p': null, 'f': null};
    return {
      'a': m['a'] as String?,
      'p': m['p'] as String?,
      'f': m['f'] as String?,
    };
  }

  static bool _inside(double x, double y, List<num> ring) {
    var ins = false;
    final n = ring.length ~/ 2;
    var j = n - 1;
    for (var i = 0; i < n; i++) {
      final xi = ring[2 * i].toDouble(), yi = ring[2 * i + 1].toDouble();
      final xj = ring[2 * j].toDouble(), yj = ring[2 * j + 1].toDouble();
      if ((yi > y) != (yj > y) &&
          x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        ins = !ins;
      }
      j = i;
    }
    return ins;
  }

  static double _bboxArea(List<num> ring) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (var i = 0; i < ring.length; i += 2) {
      final x = ring[i].toDouble(), y = ring[i + 1].toDouble();
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    return (maxX - minX) * (maxY - minY);
  }

  static double _segDist(double px, double py, double ax, double ay,
      double bx, double by, double k) {
    final dx = (bx - ax) * k, dy = by - ay;
    final ex = (px - ax) * k, ey = py - ay;
    final l = dx * dx + dy * dy;
    var t = l == 0 ? 0.0 : (ex * dx + ey * dy) / l;
    t = t.clamp(0.0, 1.0);
    return math.sqrt(math.pow(ex - t * dx, 2) + math.pow(ey - t * dy, 2));
  }

  /// Flag emoji from a 2-letter country code.
  static String flag(String code) {
    if (code.length != 2) return '🌍';
    return String.fromCharCodes(
        code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));
  }
}
