import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../i18n.dart';
import '../services/content_service.dart';
import '../theme.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  String? _message;
  bool _good = true;
  bool _busy = false;

  String _describe(String code) {
    switch (code) {
      case 'ok':
        return tr('Content updated. Everything is saved on your phone.',
            'تم تحديث المحتوى. كل شيء محفوظ على هاتفك.');
      case 'same_or_older':
        return tr('You already have this content or a newer one.',
            'لديك هذا المحتوى أو محتوى أحدث منه.');
      case 'bad_signature':
        return tr(
            'Rejected: this file is not signed by the SafePath publisher. It may be fake or damaged.',
            'مرفوض: هذا الملف غير موقّع من ناشر SafePath. قد يكون مزيفاً أو تالفاً.');
      case 'no_file':
        return tr('No update file was found online.',
            'لم يتم العثور على ملف تحديث على الإنترنت.');
      default:
        return tr('This is not a valid SafePath content file.',
            'هذا ليس ملف محتوى صالحاً لـ SafePath.');
    }
  }

  void _show(String code) {
    if (!mounted) return;
    setState(() {
      _good = code == 'ok' || code == 'same_or_older';
      _message = _describe(code);
      _busy = false;
    });
  }

  Future<void> _checkOnline() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      _show(await ContentService.checkOnline());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _good = false;
        _message = tr('No internet. Saved content still works.',
            'لا يوجد إنترنت. المحتوى المحفوظ يعمل.');
      });
    }
  }

  Future<void> _share() async {
    try {
      final bytes =
          Uint8List.fromList(utf8.encode(ContentService.envelopeText));
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              name: 'safepath-content.safepath', mimeType: 'text/plain')
        ],
        fileNameOverrides: ['safepath-content.safepath'],
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _good = false;
        _message = tr('Sharing is not available on this device.',
            'المشاركة غير متاحة على هذا الجهاز.');
      });
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.any, withData: true);
      if (r == null || r.files.isEmpty || r.files.first.bytes == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      _show(await ContentService.importText(
          utf8.decode(r.files.first.bytes!, allowMalformed: true)));
    } catch (_) {
      _show('invalid');
    }
  }

  Widget _action(IconData icon, List<Color> colors, String title, String sub,
      VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradientOf(colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(sub,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ],
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
    final d = ContentService.contentDate;
    final dateText =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Updates', 'التحديثات')),
        backgroundColor: Palette.updates.first,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Your content version: $dateText\nOnly content signed by the SafePath publisher is accepted.',
                          'نسخة المحتوى لديك: $dateText\nيُقبل فقط المحتوى الموقّع من ناشر SafePath.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _action(
            Icons.cloud_download,
            Palette.updates,
            tr('Check online', 'تحقق عبر الإنترنت'),
            tr('Download the newest content when you have internet',
                'نزّل أحدث محتوى عند توفر الإنترنت'),
            _busy ? null : _checkOnline,
          ),
          _action(
            Icons.ios_share,
            Palette.maps,
            tr('Share with a nearby phone', 'شارك مع هاتف قريب'),
            tr('Send your content by AirDrop, Bluetooth or any app. No internet needed.',
                'أرسل محتواك عبر AirDrop أو البلوتوث أو أي تطبيق. بدون إنترنت.'),
            _share,
          ),
          _action(
            Icons.file_open,
            Palette.library,
            tr('Import content file', 'استيراد ملف محتوى'),
            tr('Choose a .safepath file someone sent you',
                'اختر ملف .safepath أرسله لك أحد'),
            _busy ? null : _import,
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null)
            Card(
              color: _good ? Colors.green.shade100 : Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_message!,
                    style: const TextStyle(color: Colors.black87, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}
