import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Content packs: JSON files bundled in the app (works from first install)
/// that can be replaced by newer versions downloaded while online.
/// Downloaded packs are stored with shared_preferences, so the same code
/// works on Android, iPhone and the web.
///
/// Hosted manifest format (manifest.json):
/// {
///   "packs": [
///     {"id": "first_aid", "version": 2, "url": "https://example.com/first_aid.json"},
///     {"id": "library",   "version": 2, "url": "https://example.com/library.json"}
///   ]
/// }
class ContentService {
  /// TODO: put the public link of your hosted manifest.json here
  /// (GitHub Pages, any web host, or a raw GitHub file).
  static const String manifestUrl = '';

  /// Version of the packs that ship inside the app.
  static const int bundledVersion = 1;

  static Future<void> init() async {}

  /// Load a pack: downloaded copy if present and valid, else the bundled one.
  static Future<dynamic> load(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('packdata_$id');
      if (saved != null) return jsonDecode(saved);
    } catch (_) {
      // corrupted or unavailable - fall back to the bundled copy
    }
    return jsonDecode(await rootBundle.loadString('assets/content/$id.json'));
  }

  static Future<int> installedVersion(String id) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('pack_$id') ?? bundledVersion;
  }

  /// Returns a result code. Throws on network problems.
  static Future<String> checkAndUpdate() async {
    if (manifestUrl.isEmpty) return 'not_configured';
    final res = await http
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    final manifest = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    final packs = (manifest['packs'] as List?) ?? const [];
    final prefs = await SharedPreferences.getInstance();
    var updated = 0;
    for (final raw in packs) {
      final pack = raw as Map;
      final id = pack['id'].toString();
      final version = (pack['version'] as num).toInt();
      final url = pack['url'].toString();
      if (version <= await installedVersion(id)) continue;
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) continue;
      final text = utf8.decode(r.bodyBytes);
      jsonDecode(text); // validate before saving
      await prefs.setString('packdata_$id', text);
      await prefs.setInt('pack_$id', version);
      updated++;
    }
    return updated == 0 ? 'up_to_date' : 'updated:$updated';
  }
}
