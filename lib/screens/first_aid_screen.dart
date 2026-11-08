import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/content_service.dart';
import '../theme.dart';
import '../widgets.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ContentService.pack('first_aid') as Map?;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('First Aid', 'الإسعافات الأولية')),
        backgroundColor: Palette.firstAid.first,
      ),
      body: data == null
          ? Center(child: Text(tr('Could not load', 'تعذر التحميل')))
          : _body(context, data),
    );
  }

  Widget _body(BuildContext context, Map data) {
    final all = (data['topics'] as List).cast<Map>();
    final q = _query.toLowerCase();
    final topics = all.where((t) {
      if (q.isEmpty) return true;
      final title = '${t['title']['en']} ${t['title']['ar']}'.toLowerCase();
      return title.contains(q);
    }).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: gradientOf(Palette.firstAid)),
          padding: const EdgeInsets.all(12),
          child: Text(
            trMap(data['disclaimer']),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr('Search', 'بحث'),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: topics.length,
            itemBuilder: (context, i) {
              final t = topics[i];
              final urgent = t['urgent'] == true;
              final color = urgent ? Colors.red.shade600 : Colors.teal.shade600;
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _TopicScreen(topic: t)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 84, color: color),
                      const SizedBox(width: 10),
                      Illustration(t['image']?.toString(), width: 110, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trMap(t['title']),
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            if (urgent)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  tr('EMERGENCY', 'حالة طارئة'),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                      const SizedBox(width: 6),
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

class _TopicScreen extends StatelessWidget {
  const _TopicScreen({required this.topic});
  final Map topic;

  @override
  Widget build(BuildContext context) {
    final steps = trList(topic['steps']);
    final stepImages = (topic['step_images'] as List?) ?? const [];
    final warning = trMap(topic['warning']);
    final urgent = topic['urgent'] == true;
    final color = urgent ? Colors.red.shade600 : Colors.teal.shade600;
    return Scaffold(
      appBar: AppBar(
        title: Text(trMap(topic['title'])),
        backgroundColor: color,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Illustration(topic['image']?.toString()),
          const SizedBox(height: 12),
          if (urgent)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: gradientOf(Palette.sos),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Emergency: call your local emergency number now. Open SOS to find it.',
                          'حالة طارئة: اتصل برقم الطوارئ المحلي الآن. افتح قسم الطوارئ لمعرفته.'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < steps.length; i++)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: color,
                          child: Text('${i + 1}',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(steps[i],
                              style: const TextStyle(fontSize: 17, height: 1.35)),
                        ),
                      ],
                    ),
                    if (i < stepImages.length && stepImages[i] != null) ...[
                      const SizedBox(height: 10),
                      Illustration(stepImages[i].toString(), radius: 14),
                    ],
                  ],
                ),
              ),
            ),
          if (warning.isNotEmpty)
            Card(
              color: Colors.amber.shade100,
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(warning,
                          style: const TextStyle(color: Colors.black87)),
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
