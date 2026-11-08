import 'package:flutter/material.dart';

import 'i18n.dart';
import 'screens/chat_screen.dart';
import 'screens/first_aid_screen.dart';
import 'screens/library_screen.dart';
import 'screens/map_screen.dart';
import 'screens/radio_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/updates_screen.dart';
import 'services/content_service.dart';
import 'services/tile_cache.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLanguage();
  await ContentService.init();
  await initTileCache();
  runApp(const SafePathApp());
}

class SafePathApp extends StatelessWidget {
  const SafePathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isArabic,
      builder: (context, arabic, _) {
        return MaterialApp(
          title: 'SafePath',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: ThemeMode.system,
          builder: (context, child) => Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class _Tile {
  const _Tile(this.icon, this.en, this.ar, this.colors, this.builder,
      {this.soon = false});
  final IconData icon;
  final String en;
  final String ar;
  final List<Color> colors;
  final WidgetBuilder builder;
  final bool soon;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      _Tile(Icons.medical_services, 'First Aid', 'الإسعافات الأولية',
          Palette.firstAid, (_) => const FirstAidScreen()),
      _Tile(Icons.map, 'Maps', 'الخرائط', Palette.maps,
          (_) => const MapScreen()),
      _Tile(Icons.menu_book, 'Library', 'المكتبة', Palette.library,
          (_) => const LibraryScreen()),
      _Tile(Icons.system_update, 'Updates', 'التحديثات', Palette.updates,
          (_) => const UpdatesScreen()),
      _Tile(Icons.radio, 'Radio', 'الراديو', Palette.radio,
          (_) => const RadioScreen(),
          soon: true),
      _Tile(Icons.forum, 'Chat', 'الدردشة', Palette.chat,
          (_) => const ChatScreen(),
          soon: true),
    ];

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: ContentService.revision,
          builder: (context, _, __) {
            final notices =
                ((ContentService.pack('alerts') as Map?)?['notices'] as List?)
                        ?.cast<Map>() ??
                    const <Map>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: gradientOf(const [
                      Color(0xFF00BFA5),
                      Color(0xFF2979FF),
                    ]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SafePath',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              tr('Stay ready. Stay safe. Works offline.',
                                  'كن مستعداً. ابقَ آمناً. يعمل بدون إنترنت.'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24),
                        onPressed: () => setArabic(!isArabic.value),
                        child: Text(isArabic.value ? 'English' : 'العربية'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // SOS
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: gradientOf(Palette.sos),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x55D50000),
                          blurRadius: 12,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SosScreen()),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sos,
                                size: 44, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              tr('SOS  -  Emergency', 'طوارئ  -  نجدة'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notices from the publisher
                for (final n in notices.take(3)) _NoticeCard(notice: n),

                // Tiles
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    for (final t in tiles)
                      Container(
                        decoration: BoxDecoration(
                          gradient: gradientOf(t.colors),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: t.colors.first.withAlpha(90),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: t.builder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(t.icon, size: 52, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  tr(t.en, t.ar),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (t.soon)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tr('Coming soon', 'قريباً'),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});
  final Map notice;

  @override
  Widget build(BuildContext context) {
    final level = notice['level']?.toString() ?? 'info';
    final color = level == 'danger'
        ? Colors.red
        : (level == 'warning' ? Colors.orange : Colors.blue);
    final icon = level == 'danger'
        ? Icons.error
        : (level == 'warning' ? Icons.warning_amber : Icons.info);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trMap(notice['title']),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(trMap(notice['body'])),
                if (notice['date'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(notice['date'].toString(),
                        style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
