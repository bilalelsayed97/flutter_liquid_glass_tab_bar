import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Captures the Impeller material on a real device: resting, held, and
/// mid-drag. Run with `flutter test integration_test -d <device>`; the
/// screenshots are what the README shows.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures the resting, held, and dragged material', (
    tester,
  ) async {
    await precacheLiquidGlassShader();
    await tester.pumpWidget(const _ShaderVisualApp());
    await tester.pumpAndSettle();
    await binding.takeScreenshot('tab_bar_shader_resting');

    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final search = tester.getCenter(find.bySemanticsLabel('Search'));
    final gesture = await tester.startGesture(home);
    await tester.pump(const Duration(milliseconds: 420));
    await binding.takeScreenshot('tab_bar_shader_held');

    await gesture.moveTo(Offset.lerp(home, search, 0.5)!);
    await tester.pump(const Duration(milliseconds: 80));
    await binding.takeScreenshot('tab_bar_shader_mid_drag');

    await gesture.cancel();
    await tester.pumpAndSettle();
  });
}

class _ShaderVisualApp extends StatelessWidget {
  const _ShaderVisualApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(platform: TargetPlatform.iOS),
    home: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ColorBackdrop(),
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassTabBar(
              items: const [
                LiquidGlassTabItem(icon: Icons.home, label: 'Home'),
                LiquidGlassTabItem(icon: Icons.search, label: 'Search'),
                LiquidGlassTabItem(icon: Icons.library_music, label: 'Library'),
                LiquidGlassTabItem(icon: Icons.settings, label: 'Settings'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
              card: const _VisualCard(),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ColorBackdrop extends StatelessWidget {
  const _ColorBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF071A4D), Color(0xFF6B1D76), Color(0xFFE4A541)],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            for (final color in const [
              Color(0xFFEA3A43),
              Color(0xFF11A8A0),
              Color(0xFFF2B632),
              Color(0xFF4361EE),
            ])
              Expanded(
                child: ColoredBox(color: color, child: const SizedBox.expand()),
              ),
          ],
        ),
      ),
    ),
  );
}

class _VisualCard extends StatelessWidget {
  const _VisualCard();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x660A0A0A),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const SizedBox(
      height: 48,
      child: Center(
        child: Text('Now Playing', style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
