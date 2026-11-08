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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLanguage();
  await ContentService.init();
  await TileCache.init();
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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.dark,
            ),
          ),
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
  const _Tile(this.icon, this.en, this.ar, this.builder, {this.soon = false});
  final IconData icon;
  final String en;
  final String ar;
  final WidgetBuilder builder;
  final bool soon;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      _Tile(Icons.medical_services, 'First Aid', 'الإسعافات الأولية',
          (_) => const FirstAidScreen()),
      _Tile(Icons.map, 'Maps', 'الخرائط', (_) => const MapScreen()),
      _Tile(Icons.menu_book, 'Library', 'المكتبة', (_) => const LibraryScreen()),
      _Tile(Icons.radio, 'Radio', 'الراديو', (_) => const RadioScreen(),
          soon: true),
      _Tile(Icons.forum, 'Chat', 'الدردشة', (_) => const ChatScreen(),
          soon: true),
      _Tile(Icons.system_update, 'Updates', 'التحديثات',
          (_) => const UpdatesScreen()),
    ];

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafePath'),
        actions: [
          TextButton(
            onPressed: () => setArabic(!isArabic.value),
            child: Text(isArabic.value ? 'English' : 'العربية'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 96,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SosScreen()),
                  ),
                  icon: const Icon(Icons.sos, size: 40),
                  label: Text(
                    tr('SOS', 'طوارئ'),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final t in tiles)
                      Card(
                        color: scheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: t.builder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon,
                                  size: 44, color: scheme.onSecondaryContainer),
                              const SizedBox(height: 8),
                              Text(
                                tr(t.en, t.ar),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                              if (t.soon)
                                Text(
                                  tr('Coming soon', 'قريباً'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
