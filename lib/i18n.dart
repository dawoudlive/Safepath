import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// true = Arabic, false = English
final ValueNotifier<bool> isArabic = ValueNotifier<bool>(false);

/// Pick the text for the current language.
String tr(String en, String ar) => isArabic.value ? ar : en;

/// Read a {"en": ..., "ar": ...} map from pack JSON.
String trMap(dynamic m) {
  if (m is Map) {
    final v = isArabic.value ? m['ar'] : m['en'];
    return (v ?? m['en'] ?? '').toString();
  }
  return (m ?? '').toString();
}

List<String> trList(dynamic m) {
  if (m is Map) {
    final v = isArabic.value ? m['ar'] : m['en'];
    final l = (v ?? m['en']) as List?;
    return (l ?? const []).map((e) => e.toString()).toList();
  }
  return const [];
}

Future<void> loadLanguage() async {
  try {
    final p = await SharedPreferences.getInstance();
    isArabic.value = p.getBool('arabic') ?? false;
  } catch (_) {}
}

Future<void> setArabic(bool value) async {
  isArabic.value = value;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool('arabic', value);
  } catch (_) {}
}
