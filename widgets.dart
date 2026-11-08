import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

final Map<String, String> _svgCache = {};

/// Shows an illustration from assets/img/<name>.svg (shows nothing if the
/// picture does not exist, so newer content never breaks older apps).
class Illustration extends StatelessWidget {
  const Illustration(this.name, {super.key, this.radius = 18, this.width});

  final String? name;
  final double radius;
  final double? width;

  Future<String?> _load() async {
    final n = name;
    if (n == null || n.isEmpty) return null;
    final cached = _svgCache[n];
    if (cached != null) return cached;
    try {
      final s = await rootBundle.loadString('assets/img/$n.svg');
      _svgCache[n] = s;
      return s;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || name!.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _load(),
      builder: (context, snap) {
        final svg = snap.data;
        if (svg == null) {
          return SizedBox(width: width);
        }
        return SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AspectRatio(
              aspectRatio: 400 / 260,
              child: SvgPicture.string(svg, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}
