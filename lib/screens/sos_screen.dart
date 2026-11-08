import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final TextEditingController _contact = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    try {
      final p = await SharedPreferences.getInstance();
      _contact.text = p.getString('sos_contact') ?? '';
    } catch (_) {}
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
      final pos = await Geolocator.getCurrentPosition();
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

  Widget _callButton(String label, String number, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: () => _call(number),
        icon: const Icon(Icons.call),
        label: Text('$label  $number', style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('SOS', 'طوارئ'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _callButton(tr('Qatar emergency', 'طوارئ قطر'), '999',
              Colors.red.shade700),
          const SizedBox(height: 12),
          _callButton(tr('Egypt ambulance', 'إسعاف مصر'), '123',
              Colors.red.shade900),
          const SizedBox(height: 24),
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
              labelText: tr('Emergency contact number',
                  'رقم جهة اتصال الطوارئ'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
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
              'SMS works with mobile signal even without internet. '
                  'You press Send in your messages app.',
              'الرسائل النصية تعمل مع إشارة الشبكة حتى بدون إنترنت. '
                  'اضغط إرسال في تطبيق الرسائل.',
            ),
          ),
        ],
      ),
    );
  }
}
