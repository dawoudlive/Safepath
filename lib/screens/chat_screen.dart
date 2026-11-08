import 'package:flutter/material.dart';

import '../i18n.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Chat', 'الدردشة'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.forum, size: 64),
            const SizedBox(height: 16),
            Text(tr('Coming in a later version', 'قريباً في إصدار لاحق'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              tr(
                'Planned: chat with nearby phones over Bluetooth / Wi-Fi '
                    'Direct, with no internet and no mobile network.',
                'مخطط: دردشة مع الهواتف القريبة عبر البلوتوث / Wi-Fi Direct '
                    'بدون إنترنت وبدون شبكة جوال.',
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
