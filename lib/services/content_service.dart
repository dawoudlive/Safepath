import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Content = first aid, library and notices.
///
/// It ships inside the app as a signed file (assets/content/bundle.safepath).
/// A newer signed file can arrive two ways, with the same checks for both:
///   1. downloaded when online from [updateUrl], or
///   2. imported from a file shared by another phone (AirDrop, Bluetooth...).
///
/// A content file is accepted only if it carries a valid signature from the
/// SafePath publisher key ([publicKeyB64]), checked offline, and is newer
/// than what the phone already has.
class ContentService {
  /// Where the newest signed content file is published when online.
  static const String updateUrl =
      'https://dawoudlive.github.io/Safepath/packs/latest.safepath';

  /// Publisher public key (Ed25519, base64). Only content signed by the
  /// matching private key is accepted.
  static const String publicKeyB64 = 's8WIJSsi/3uEx9Kwdh65rP3fMGBrHHB75YJMgCgvnMc=';

  static const String _prefsKey = 'envelope_v1';

  static Map<String, dynamic> _packs = {};
  static int _seq = 0;
  static String _envelopeText = '';

  /// Changes every time new content is installed, so screens can refresh.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static int get seq => _seq;
  static String get envelopeText => _envelopeText;

  static Future<void> init() async {
    final bundle = await rootBundle.loadString('assets/content/bundle.safepath');
    var chosen = bundle;
    var chosenSeq = _seqOf(bundle);

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        final savedSeq = _seqOf(saved);
        if (savedSeq > chosenSeq && await _verify(saved)) {
          chosen = saved;
          chosenSeq = savedSeq;
        }
      }
    } catch (_) {
      // fall back to the bundled content
    }

    _apply(chosen);
  }

  static int _seqOf(String text) {
    try {
      return ((jsonDecode(text) as Map)['seq'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  static void _apply(String text) {
    final env = jsonDecode(text) as Map;
    _packs = jsonDecode(env['payload'] as String) as Map<String, dynamic>;
    _seq = (env['seq'] as num).toInt();
    _envelopeText = text;
    revision.value++;
  }

  /// A pack by id: 'first_aid', 'library' or 'alerts'.
  static Future<dynamic> load(String id) async => _packs[id];

  static dynamic pack(String id) => _packs[id];

  static DateTime get contentDate =>
      DateTime.fromMillisecondsSinceEpoch(_seq * 1000, isUtc: true);

  static Future<bool> _verify(String text) async {
    try {
      final env = jsonDecode(text) as Map;
      if (env['format'] != 'safepath-pack-v1') return false;
      final pub = SimplePublicKey(base64Decode(publicKeyB64),
          type: KeyPairType.ed25519);
      final sig = Signature(base64Decode(env['sig'] as String), publicKey: pub);
      final message = utf8.encode('${env['seq']}\n${env['payload']}');
      return await Ed25519().verify(message, signature: sig);
    } catch (_) {
      return false;
    }
  }

  /// Result codes: ok, same_or_older, bad_signature, invalid.
  static Future<String> importText(String text) async {
    Map env;
    try {
      env = jsonDecode(text) as Map;
      if (env['format'] != 'safepath-pack-v1' ||
          env['payload'] is! String ||
          env['sig'] is! String ||
          env['seq'] is! num) {
        return 'invalid';
      }
    } catch (_) {
      return 'invalid';
    }
    if (!await _verify(text)) return 'bad_signature';
    final newSeq = (env['seq'] as num).toInt();
    if (newSeq <= _seq) return 'same_or_older';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, text);
    } catch (_) {
      return 'invalid';
    }
    _apply(text);
    return 'ok';
  }

  /// Download the newest published content when online.
  /// Throws on network problems.
  static Future<String> checkOnline() async {
    final res = await http
        .get(Uri.parse(updateUrl))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return 'no_file';
    return importText(utf8.decode(res.bodyBytes));
  }
}
