import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/content_service.dart';

IconData _icon(String name) {
  switch (name) {
    case 'bleeding':
      return Icons.bloodtype;
    case 'cpr':
      return Icons.favorite;
    case 'choking':
      return Icons.air;
    case 'burn':
      return Icons.local_fire_department;
    case 'fracture':
      return Icons.healing;
    case 'heat':
      return Icons.thermostat;
    case 'shock':
      return Icons.warning_amber;
    case 'recovery':
      return Icons.hotel;
    case 'poison':
      return Icons.science;
    case 'wound':
      return Icons.cleaning_services;
    default:
      return Icons.medical_services;
  }
}

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  late final Future<dynamic> _future = ContentService.load('first_aid');
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('First Aid', 'الإسعافات الأولية'))),
      body: FutureBuilder<dynamic>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text(tr('Could not load', 'تعذر التحميل')));
          }
          final data = snap.data as Map;
          final all = (data['topics'] as List).cast<Map>();
          final topics = all.where((t) {
            if (_query.isEmpty) return true;
            return trMap(t['title']).toLowerCase().contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.all(12),
                child: Text(
                  trMap(data['disclaimer']),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr('Search', 'بحث'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, i) {
                    final t = topics[i];
                    final urgent = t['urgent'] == true;
                    return ListTile(
                      leading: Icon(
                        _icon(t['icon'].toString()),
                        color: urgent ? Colors.red.shade700 : null,
                        size: 32,
                      ),
                      title: Text(trMap(t['title'])),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _TopicScreen(topic: t)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopicScreen extends StatelessWidget {
  const _TopicScreen({required this.topic});
  final Map topic;

  @override
  Widget build(BuildContext context) {
    final steps = trList(topic['steps']);
    final warning = trMap(topic['warning']);
    return Scaffold(
      appBar: AppBar(title: Text(trMap(topic['title']))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (topic['urgent'] == true)
            Card(
              color: Colors.red.shade700,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr('Emergency: call local emergency services now (Qatar 999).',
                      'حالة طارئة: اتصل بالإسعاف الآن (قطر 999).'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 14, child: Text('${i + 1}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(steps[i], style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          if (warning.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(warning),
              ),
            ),
        ],
      ),
    );
  }
}
