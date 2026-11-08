import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/content_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  String? _message;
  bool _busy = false;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String msg;
    try {
      final r = await ContentService.checkAndUpdate();
      if (r == 'not_configured') {
        msg = tr('Update server is not set up yet.',
            'خادم التحديثات غير مُعدّ بعد.');
      } else if (r == 'up_to_date') {
        msg = tr('Everything is up to date.', 'كل شيء محدّث.');
      } else {
        msg = tr('Updated ${r.split(':').last} content pack(s).',
            'تم تحديث ${r.split(':').last} من حزم المحتوى.');
      }
    } catch (_) {
      msg = tr('No internet or server unreachable. Saved content still works.',
          'لا يوجد إنترنت أو الخادم غير متاح. المحتوى المحفوظ يعمل.');
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Updates', 'التحديثات'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              'First aid and library content is saved on your phone and works '
                  'without internet. When you are online, tap the button to '
                  'download newer content.',
              'محتوى الإسعافات والمكتبة محفوظ على هاتفك ويعمل بدون إنترنت. '
                  'عند توفر الإنترنت اضغط الزر لتنزيل محتوى أحدث.',
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(tr('Check for updates', 'البحث عن تحديثات')),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: const TextStyle(fontSize: 16)),
          ],
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(tr('Share content with nearby phone',
                'مشاركة المحتوى مع هاتف قريب')),
            subtitle: Text(tr('Coming soon', 'قريباً')),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
