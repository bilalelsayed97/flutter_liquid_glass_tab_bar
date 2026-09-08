import 'package:flutter/widgets.dart';

/// Stand-in for a mini player: the bar only ever positions whatever widget
/// it is handed. Bare — the bar adds the edge and bottom padding itself.
class FakeCard extends StatelessWidget {
  const FakeCard({super.key, this.height = 56});

  /// A real card grows with its content and the text scale; the taller
  /// variant is what exposes vertical-alignment bugs in the split layout.
  final double height;

  /// Marks the visible glass.
  static const Key glassKey = ValueKey('fake-card-glass');

  @override
  Widget build(BuildContext context) => Container(
    key: glassKey,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0x33000000),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

/// Counts how often the bar rebuilds its card child.
class BuildCounter extends StatelessWidget {
  final VoidCallback onBuild;

  const BuildCounter({super.key, required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const FakeCard();
  }
}
