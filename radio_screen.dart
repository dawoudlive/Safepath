import 'package:flutter/material.dart';

import '../i18n.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Radio', 'الراديو'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.radio, size: 64),
            const SizedBox(height: 16),
            Text(tr('Coming in a later version', 'قريباً في إصدار لاحق'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              tr(
                'Planned: saved audio to play offline, and support for an '
                    'external radio receiver. Phones cannot receive FM/AM '
                    'radio through an app alone.',
                'مخطط: صوتيات محفوظة للتشغيل بدون إنترنت، ودعم جهاز استقبال '
                    'راديو خارجي. الهواتف لا تستقبل FM/AM عبر التطبيق وحده.',
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
