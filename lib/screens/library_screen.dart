import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/content_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Library', 'المكتبة'))),
      body: FutureBuilder<dynamic>(
        future: ContentService.load('library'),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text(tr('Could not load', 'تعذر التحميل')));
          }
          final books = ((snap.data as Map)['books'] as List).cast<Map>();
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, i) {
              final b = books[i];
              return ListTile(
                leading: const Icon(Icons.menu_book, size: 32),
                title: Text(trMap(b['title'])),
                subtitle: Text(trMap(b['summary'])),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _BookScreen(book: b)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookScreen extends StatelessWidget {
  const _BookScreen({required this.book});
  final Map book;

  @override
  Widget build(BuildContext context) {
    final sections = (book['sections'] as List).cast<Map>();
    return Scaffold(
      appBar: AppBar(title: Text(trMap(book['title']))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in sections) ...[
            Text(
              trMap(s['heading']),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final line in trList(s['items']))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontSize: 17)),
                    Expanded(
                      child: Text(line, style: const TextStyle(fontSize: 17)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
