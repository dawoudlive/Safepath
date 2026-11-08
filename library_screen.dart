import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/content_service.dart';
import '../theme.dart';
import '../widgets.dart';

IconData _catIcon(String name) {
  switch (name) {
    case 'shield':
      return Icons.shield;
    case 'water':
      return Icons.water_drop;
    case 'home':
      return Icons.cabin;
    case 'plant':
      return Icons.eco;
    case 'health':
      return Icons.favorite;
    case 'compass':
      return Icons.explore;
    case 'power':
      return Icons.battery_charging_full;
    default:
      return Icons.menu_book;
  }
}

Color _catColor(dynamic index) {
  final i = (index is num) ? index.toInt() : 0;
  return Palette.category[i % Palette.category.length];
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  String? _category; // null = all

  bool _matches(Map b, String q) {
    if (q.isEmpty) return true;
    final buf = StringBuffer()
      ..write('${b['title']['en']} ${b['title']['ar']} ')
      ..write('${b['summary']['en']} ${b['summary']['ar']} ');
    for (final s in (b['sections'] as List).cast<Map>()) {
      buf.write('${s['heading']['en']} ${s['heading']['ar']} ');
      for (final l in ['en', 'ar']) {
        for (final it in (s['items'][l] as List)) {
          buf.write('$it ');
        }
      }
    }
    return buf.toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final data = ContentService.pack('library') as Map?;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Library', 'المكتبة')),
        backgroundColor: Palette.library.first,
      ),
      body: data == null
          ? Center(child: Text(tr('Could not load', 'تعذر التحميل')))
          : _body(context, data),
    );
  }

  Widget _body(BuildContext context, Map data) {
    final cats = (data['categories'] as List).cast<Map>();
    final catById = {for (final c in cats) c['id'].toString(): c};
    final q = _query.toLowerCase().trim();
    final books = (data['books'] as List).cast<Map>().where((b) {
      if (_category != null && b['category'] != _category) return false;
      return _matches(b, q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr('Search all guides', 'ابحث في كل الأدلة'),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(tr('All', 'الكل')),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in cats)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    avatar: Icon(_catIcon(c['icon'].toString()),
                        size: 18, color: _catColor(c['color'])),
                    label: Text(trMap(c['title'])),
                    selected: _category == c['id'],
                    selectedColor: _catColor(c['color']).withAlpha(60),
                    onSelected: (_) =>
                        setState(() => _category = c['id'].toString()),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: books.isEmpty
              ? Center(child: Text(tr('Nothing found', 'لا نتائج')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final b = books[i];
                    final cat = catById[b['category']];
                    final color = _catColor(cat?['color']);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _BookScreen(book: b, color: color)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 84, color: color),
                            const SizedBox(width: 10),
                            Illustration(b['image']?.toString(),
                                width: 110, radius: 12),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cat != null)
                                      Text(
                                        trMap(cat['title']),
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    Text(
                                      trMap(b['title']),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      trMap(b['summary']),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BookScreen extends StatelessWidget {
  const _BookScreen({required this.book, required this.color});
  final Map book;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sections = (book['sections'] as List).cast<Map>();
    return Scaffold(
      appBar: AppBar(
        title: Text(trMap(book['title'])),
        backgroundColor: color,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Illustration(book['image']?.toString()),
          const SizedBox(height: 8),
          for (final s in sections)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trMap(s['heading']),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (s['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Illustration(s['image'].toString(), radius: 14),
                      ),
                    for (final line in trList(s['items']))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Icon(Icons.circle, size: 9, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(line,
                                  style: const TextStyle(
                                      fontSize: 16, height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
