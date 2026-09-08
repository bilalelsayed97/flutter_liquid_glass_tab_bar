import 'package:flutter/widgets.dart';

/// Deterministic high-colour backdrop that exposes milky or uniform glass.
class GlassTestBackground extends StatelessWidget {
  final Widget child;

  const GlassTestBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Color(0xFF6FB7FF), Color(0xFFFF8A5C), Color(0xFF1E8E5A)],
      ),
    ),
    child: child,
  );
}
