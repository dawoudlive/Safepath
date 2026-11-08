import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../services/country_service.dart';
import '../theme.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final TextEditingController _contact = TextEditingController();

  String? _code; // ISO country code
  String _countryName = '';
  Map<String, String?> _numbers = {'a': null, 'p': null, 'f': null};
  bool _detecting = true;
  bool _manual = false;
  String? _gpsNote;
  Position? _pos;
  String? _status;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _contact.text = p.getString('sos_contact') ?? '';
      final saved = p.getString('sos_country');
      final manual = p.getBool('sos_country_manual') ?? false;
      if (saved != null) {
        await _setCountry(saved, manual: manual, save: false);
      }
      if (manual) {
        setState(() => _detecting = false);
        return;
      }
    } catch (_) {}
    await _detect();
  }

  Future<void> _setCountry(String code,
      {required bool manual, bool save = true}) async {
    final name = await CountryService.nameOf(code);
    final nums = await CountryService.numbersFor(code);
    if (!mounted) return;
    setState(() {
      _code = code;
      _countryName = name;
      _numbers = nums;
      _manual = manual;
    });
    if (save) {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString('sos_country', code);
        await p.setBool('sos_country_manual', manual);
      } catch (_) {}
    }
  }

  Future<void> _detect() async {
    setState(() {
      _detecting = true;
      _gpsNote = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('permission');
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      _pos = pos;
      final code = await CountryService.codeFor(pos.latitude, pos.longitude);
      if (code != null) {
        await _setCountry(code, manual: false);
      } else {
        _gpsNote = tr('Could not match a country. Choose your country.',
            'تعذر تحديد الدولة. اختر دولتك.');
      }
    } catch (_) {
      _gpsNote = _code == null
          ? tr('GPS not available. Choose your country.',
              'GPS غير متاح. اختر دولتك.')
          : tr('GPS not available. Showing the last country used.',
              'GPS غير متاح. يتم عرض آخر دولة مستخدمة.');
    }
    if (mounted) setState(() => _detecting = false);
  }

  Future<void> _pickCountry() async {
    final all = await CountryService.allCountries();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountryPicker(all: all),
    );
    if (chosen != null) {
      await _setCountry(chosen, manual: true);
      if (mounted) setState(() => _gpsNote = null);
    }
  }

  Future<void> _call(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  Future<void> _sendLocation() async {
    setState(() => _status = tr('Getting location...', 'جاري تحديد الموقع...'));
    String where;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = _pos ??
          await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 15));
      where = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}'
          '  (${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)})';
    } catch (_) {
      where = tr('Location unavailable', 'الموقع غير متاح');
    }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('sos_contact', _contact.text.trim());
    } catch (_) {}
    final body = Uri.encodeComponent(
        tr('SOS! I need help. My location: ', 'نجدة! أحتاج مساعدة. موقعي: ') +
            where);
    final number = _contact.text.trim();
    await launchUrl(Uri.parse('sms:$number?body=$body'));
    if (mounted) setState(() => _status = null);
  }

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Widget _bigCall(String label, String number, List<Color> colors, IconData icon,
      {double height = 96}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradientOf(colors),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _call(number),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '$label  $number',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _numbers['a'], p = _numbers['p'], f = _numbers['f'];
    final hasAny = a != null || p != null || f != null;
    final primary = a ?? p ?? f ?? '112';
    final showPolice = p != null && p != primary;
    final showFire = f != null && f != primary;
    final primaryLabel = a != null
        ? tr('Ambulance', 'إسعاف')
        : (p != null ? tr('Police', 'شرطة') : tr('Emergency', 'طوارئ'));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('SOS', 'طوارئ')),
        backgroundColor: Colors.red.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Where am I?
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(_code == null ? '📍' : CountryService.flag(_code!),
                      style: const TextStyle(fontSize: 38)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detecting
                              ? tr('Finding your country...',
                                  'جاري تحديد دولتك...')
                              : (_code == null
                                  ? tr('Country not set', 'لم يتم تحديد الدولة')
                                  : _countryName),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(_manual
                            ? tr('Chosen by you', 'اخترتها أنت')
                            : tr('Detected by GPS (works offline)',
                                'تم تحديدها عبر GPS (تعمل بدون إنترنت)')),
                      ],
                    ),
                  ),
                  if (_detecting)
                    const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      tooltip: tr('Refresh with GPS', 'تحديث عبر GPS'),
                      onPressed: () async {
                        try {
                          final p = await SharedPreferences.getInstance();
                          await p.setBool('sos_country_manual', false);
                        } catch (_) {}
                        setState(() => _manual = false);
                        _detect();
                      },
                      icon: const Icon(Icons.my_location),
                    ),
                  TextButton(
                    onPressed: _pickCountry,
                    child: Text(tr('Change', 'تغيير')),
                  ),
                ],
              ),
            ),
          ),
          if (_gpsNote != null) ...[
            const SizedBox(height: 8),
            Text(_gpsNote!),
          ],
          const SizedBox(height: 16),

          // Big emergency button for this country
          _bigCall(primaryLabel, primary, Palette.sos, Icons.call),
          if (showPolice || showFire) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (showPolice)
                  Expanded(
                    child: _bigCall(tr('Police', 'شرطة'), p!, Palette.maps,
                        Icons.local_police,
                        height: 70),
                  ),
                if (showPolice && showFire) const SizedBox(width: 12),
                if (showFire)
                  Expanded(
                    child: _bigCall(tr('Fire', 'إطفاء'), f!, Palette.radio,
                        Icons.local_fire_department,
                        height: 70),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            hasAny
                ? tr(
                    'Numbers can change. If a call does not connect, try 112 - on most mobile networks it forwards to the local emergency service.',
                    'قد تتغير الأرقام. إذا لم يتم الاتصال جرّب 112 - في معظم شبكات الجوال يتم تحويله إلى خدمة الطوارئ المحلية.')
                : tr(
                    'No saved number for this place. 112 works on most mobile networks and forwards to the local emergency service.',
                    'لا يوجد رقم محفوظ لهذا المكان. الرقم 112 يعمل في معظم شبكات الجوال ويحوّل إلى خدمة الطوارئ المحلية.'),
            style: const TextStyle(fontSize: 13),
          ),
          if (primary != '112') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _call('112'),
              icon: const Icon(Icons.phone_in_talk),
              label: Text(tr('Try 112 (international)', 'جرّب 112 (دولي)')),
            ),
          ],
          const SizedBox(height: 24),

          // SMS location
          Text(
            tr('Send my GPS location by SMS', 'أرسل موقعي برسالة SMS'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contact,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText:
                  tr('Emergency contact number', 'رقم جهة اتصال الطوارئ'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: _sendLocation,
              icon: const Icon(Icons.sms),
              label: Text(tr('Prepare SOS message', 'تجهيز رسالة الطوارئ')),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!),
          ],
          const SizedBox(height: 12),
          Text(
            tr(
              'SMS works with mobile signal even without internet. You press Send in your messages app.',
              'الرسائل النصية تعمل مع إشارة الشبكة حتى بدون إنترنت. اضغط إرسال في تطبيق الرسائل.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({required this.all});
  final List<MapEntry<String, String>> all;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.all
        .where((e) => e.value.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: tr('Search country', 'ابحث عن دولة'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final e = items[i];
                  return ListTile(
                    leading: Text(CountryService.flag(e.key),
                        style: const TextStyle(fontSize: 26)),
                    title: Text(e.value),
                    onTap: () => Navigator.pop(context, e.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
