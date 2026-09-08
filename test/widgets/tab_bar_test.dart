import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_liquid_glass_tab_bar/src/shader/shader_backdrop.dart';
import 'package:flutter_liquid_glass_tab_bar/src/widgets/glass_surface.dart';
import 'package:flutter_liquid_glass_tab_bar/src/widgets/pill.dart';
import 'package:flutter_liquid_glass_tab_bar/src/widgets/selection_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_card.dart';
import '../support/glass_test_background.dart';
import '../support/pump_tab_bar.dart';

const _items = [
  LiquidGlassTabItem(icon: Icons.home, label: 'Home'),
  LiquidGlassTabItem(icon: Icons.search, label: 'Search'),
  LiquidGlassTabItem(icon: Icons.library_music, label: 'Library'),
  LiquidGlassTabItem(icon: Icons.settings, label: 'Settings'),
];

void main() {
  Widget bar({
    List<LiquidGlassTabItem> items = _items,
    LiquidGlassTabLayout layout = LiquidGlassTabLayout.docked,
    int selected = 2,
    Widget? card = const FakeCard(),
    ValueChanged<int>? onSelect,
    bool colorful = false,
    LiquidGlassTabBarTheme? theme,
  }) => Builder(
    builder: (context) {
      final content = Align(
        alignment: Alignment.bottomCenter,
        child: LiquidGlassTabBar(
          items: items,
          selectedIndex: selected,
          layout: layout,
          onSelect: onSelect ?? (_) {},
          card: card,
          theme: theme,
        ),
      );
      if (colorful) return GlassTestBackground(child: content);
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: content,
      );
    },
  );

  group('goldens', () {
    testWidgets('docked, light, LTR', (tester) async {
      await pumpTabBar(tester, bar());
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_docked_light_ltr.png'),
      );
    });

    testWidgets('docked, light, RTL', (tester) async {
      await pumpTabBar(tester, bar(), rtl: true);
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_docked_light_rtl.png'),
      );
    });

    testWidgets('docked, dark', (tester) async {
      await pumpTabBar(tester, bar(), dark: true);
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_docked_dark_ltr.png'),
      );
    });

    testWidgets('docked glass over a colourful backdrop', (tester) async {
      await pumpTabBar(tester, bar(colorful: true));
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_glass_color_light_ltr.png'),
      );
    });

    testWidgets('docked at 2.0 text scale drops the labels', (tester) async {
      await pumpTabBar(tester, bar(), textScale: 2.0);
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_docked_scale2_ltr.png'),
      );
    });

    testWidgets('split, light, LTR', (tester) async {
      await pumpTabBar(tester, bar(layout: LiquidGlassTabLayout.split));
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_split_light_ltr.png'),
      );
    });

    testWidgets('mid-drag lens stretches without becoming opaque', (
      tester,
    ) async {
      await pumpTabBar(tester, bar(selected: 0));
      final home = tester.getCenter(find.bySemanticsLabel('Home'));
      final search = tester.getCenter(find.bySemanticsLabel('Search'));
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(Offset.lerp(home, search, 0.5)!);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_mid_drag_light_ltr.png'),
      );
      await gesture.cancel();
    });

    testWidgets('three tabs, docked and split', (tester) async {
      final three = _items.sublist(0, 3);
      await pumpTabBar(tester, bar(items: three, selected: 1));
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_three_docked_light_ltr.png'),
      );
      await pumpTabBar(
        tester,
        bar(items: three, selected: 0, layout: LiquidGlassTabLayout.split),
      );
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_three_split_light_ltr.png'),
      );
    });

    testWidgets('five tabs mid-morph keeps asymmetric pills', (tester) async {
      final five = [
        ..._items,
        const LiquidGlassTabItem(icon: Icons.person, label: 'Me'),
      ];
      var layout = LiquidGlassTabLayout.docked;
      late StateSetter setLayout;
      await pumpTabBar(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setLayout = setState;
            return bar(
              items: five,
              selected: 0,
              layout: layout,
              colorful: true,
            );
          },
        ),
        settle: false,
      );
      await tester.pump();
      setLayout(() => layout = LiquidGlassTabLayout.split);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final pills = tester
          .widgetList<GlassPill>(find.byType(GlassPill))
          .toList();
      final leading = tester.getRect(find.byWidget(pills.first));
      final trailing = tester.getRect(find.byWidget(pills.last));
      expect(trailing.width, greaterThan(leading.width));

      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_five_mid_morph_light_ltr.png'),
      );
      await tester.pumpAndSettle();
    });
  });

  testWidgets('the constructor is usable as const', (tester) async {
    await pumpTabBar(
      tester,
      const LiquidGlassTabBar(
        items: _items,
        selectedIndex: 0,
        onSelect: _ignore,
      ),
    );
    expect(find.byType(LiquidGlassTabBar), findsOneWidget);
  });

  testWidgets('uses the fallback glass without Impeller shaders', (
    tester,
  ) async {
    expect(LiquidGlassShaderSupport.isAvailable, isFalse);
    await pumpTabBar(tester, bar());

    final surface = find.byType(GlassSurface);
    expect(
      find.descendant(of: surface, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: surface, matching: find.byType(GlassShaderBackdrop)),
      findsNothing,
    );
  });

  testWidgets(
    'theme colours reach the surface and the lens tint is idle-only',
    (
      tester,
    ) async {
      const navigationTint = Color(0xFF5A73D8);
      const selectedTint = Color(0xFFC85A8E);
      final theme = LiquidGlassTabBarTheme.light().copyWith(
        tint: navigationTint,
        indicatorColor: selectedTint,
      );
      await pumpTabBar(tester, bar(selected: 0, theme: theme));

      GlassSurface surface() => tester.widget(find.byType(GlassSurface));
      expect(surface().params.tint, navigationTint);
      expect(surface().params.selectedPillTint, selectedTint);

      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Home')),
      );
      await tester.pump();
      expect(surface().params.selectedPillTint.a, 0);

      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(surface().params.selectedPillTint, selectedTint);
    },
  );

  testWidgets('without a card the bar is pills only and never splits', (
    tester,
  ) async {
    await pumpTabBar(
      tester,
      bar(card: null, layout: LiquidGlassTabLayout.split),
    );
    final pills = tester.widgetList<GlassPill>(find.byType(GlassPill)).toList();
    final leading = tester.getRect(find.byWidget(pills.first));
    final trailing = tester.getRect(find.byWidget(pills.last));
    expect(trailing.left - leading.right, closeTo(0, 0.5));
  });

  testWidgets('split centres a taller card against the tab pills', (
    tester,
  ) async {
    await pumpTabBar(
      tester,
      bar(layout: LiquidGlassTabLayout.split, card: const FakeCard(height: 84)),
    );
    final card = tester.getRect(find.byKey(FakeCard.glassKey));
    final pill = tester.getRect(find.byType(GlassPill).first);
    final barBounds = tester.getRect(find.byType(LiquidGlassTabBar));
    expect(card.center.dy, closeTo(pill.center.dy, 1));
    expect(card.left, greaterThanOrEqualTo(barBounds.left));
    expect(card.right, lessThanOrEqualTo(barBounds.right));
  });

  testWidgets('dragging along the bar selects only on release', (tester) async {
    final selected = <int>[];
    await pumpTabBar(tester, bar(onSelect: selected.add));

    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final settings = tester.getCenter(find.bySemanticsLabel('Settings'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(settings);
    await tester.pump();
    expect(selected, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [3]);
  });

  testWidgets('repeated drag reversals settle on the final release tab', (
    tester,
  ) async {
    final selected = <int>[];
    await pumpTabBar(tester, bar(selected: 0, onSelect: selected.add));

    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final search = tester.getCenter(find.bySemanticsLabel('Search'));
    final settings = tester.getCenter(find.bySemanticsLabel('Settings'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(settings);
    await gesture.moveTo(search);
    await gesture.moveTo(settings);
    await gesture.moveTo(search);
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, [1]);
  });

  testWidgets('selected lens follows the pointer continuously', (tester) async {
    await pumpTabBar(tester, bar(selected: 0));
    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final search = tester.getCenter(find.bySemanticsLabel('Search'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(Offset.lerp(home, search, 0.5)!);
    await tester.pump();

    final lens = tester.getRect(find.byType(GlassSelectionHighlight));
    expect(lens.center.dx, closeTo((home.dx + search.dx) / 2, 1));

    await gesture.cancel();
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byType(GlassSelectionHighlight));
    expect(settled.center.dx, closeTo(home.dx, 1));
  });

  testWidgets('external committed selection settles without a jump', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter update;
    await pumpTabBar(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return bar(selected: selected);
        },
      ),
    );

    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final settings = tester.getCenter(find.bySemanticsLabel('Settings'));
    update(() => selected = 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final travelling = tester.getRect(find.byType(GlassSelectionHighlight));
    expect(travelling.center.dx, greaterThan(home.dx));
    expect(travelling.center.dx, lessThan(settings.dx));

    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byType(GlassSelectionHighlight));
    expect(settled.center.dx, closeTo(settings.dx, 1));
  });

  testWidgets('pointer frames do not rebuild the card child', (tester) async {
    var buildCount = 0;
    await pumpTabBar(
      tester,
      bar(card: BuildCounter(onBuild: () => buildCount++)),
    );
    final settledBuildCount = buildCount;
    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final settings = tester.getCenter(find.bySemanticsLabel('Settings'));
    final gesture = await tester.startGesture(home);
    for (final fraction in <double>[0.25, 0.5, 0.75, 1]) {
      await gesture.moveTo(Offset.lerp(home, settings, fraction)!);
      await tester.pump();
    }
    expect(buildCount, settledBuildCount);
    await gesture.cancel();
  });

  testWidgets('RTL drag keeps logical tab indexes unchanged', (tester) async {
    final selected = <int>[];
    await pumpTabBar(
      tester,
      bar(selected: 0, onSelect: selected.add),
      rtl: true,
    );
    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final settings = tester.getCenter(find.bySemanticsLabel('Settings'));
    expect(home.dx, greaterThan(settings.dx));

    final gesture = await tester.startGesture(home);
    await gesture.moveTo(settings);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, [3]);
  });

  testWidgets('candidate haptic fires once despite boundary jitter', (
    tester,
  ) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpTabBar(tester, bar(selected: 0));

    final home = tester.getCenter(find.bySemanticsLabel('Home'));
    final search = tester.getCenter(find.bySemanticsLabel('Search'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(search);
    await tester.pump();
    await gesture.moveTo(search.translate(-1, 0));
    await tester.pump();
    await gesture.moveTo(search.translate(1, 0));
    await tester.pump();

    expect(haptics, hasLength(1));
    await gesture.cancel();
  });

  testWidgets('a plain tap selects the tapped tab', (tester) async {
    final selected = <int>[];
    await pumpTabBar(tester, bar(onSelect: selected.add));

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    expect(selected, [1]);
    final search = tester.getCenter(find.bySemanticsLabel('Search'));
    final lens = tester.getRect(find.byType(GlassSelectionHighlight));
    expect(lens.center.dx, closeTo(search.dx, 1));
  });

  testWidgets('every tab is a labelled, selectable button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTabBar(tester, bar());

    final semantics = tester.getSemantics(find.bySemanticsLabel('Library'));
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('a custom semantic label is what the screen reader hears', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTabBar(
      tester,
      bar(
        items: [
          const LiquidGlassTabItem(
            icon: Icons.home,
            label: 'Home',
            semanticLabel: 'Home tab',
          ),
          ..._items.sublist(1),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Home tab'), findsOneWidget);
    handle.dispose();
  });

  group('morph', () {
    Future<void Function(LiquidGlassTabLayout)> pumpFlippable(
      WidgetTester tester,
    ) async {
      var layout = LiquidGlassTabLayout.docked;
      late StateSetter setLayout;
      await pumpTabBar(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setLayout = setState;
            return bar(layout: layout, colorful: true);
          },
        ),
        settle: false,
      );
      await tester.pump();
      return (LiquidGlassTabLayout next) => setLayout(() => layout = next);
    }

    double pillGap(WidgetTester tester) {
      final pills = tester
          .widgetList<GlassPill>(find.byType(GlassPill))
          .toList();
      final leading = tester.getRect(find.byWidget(pills.first));
      final trailing = tester.getRect(find.byWidget(pills.last));
      return trailing.left - leading.right;
    }

    testWidgets('settles fully split, then fully docked again', (tester) async {
      final flip = await pumpFlippable(tester);
      expect(pillGap(tester), closeTo(0, 0.5));

      flip(LiquidGlassTabLayout.split);
      await tester.pumpAndSettle();
      expect(pillGap(tester), greaterThan(100));

      flip(LiquidGlassTabLayout.docked);
      await tester.pumpAndSettle();
      expect(pillGap(tester), closeTo(0, 0.5));
    });

    testWidgets('mid-morph keeps one continuous glass colour', (tester) async {
      final flip = await pumpFlippable(tester);
      flip(LiquidGlassTabLayout.split);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      await expectLater(
        find.byType(LiquidGlassTabBar),
        matchesGoldenFile('goldens/tab_bar_mid_morph_light_ltr.png'),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('a reversal mid-flight still reaches an endpoint', (
      tester,
    ) async {
      final flip = await pumpFlippable(tester);
      flip(LiquidGlassTabLayout.split);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pillGap(tester), greaterThan(0));

      flip(LiquidGlassTabLayout.docked);
      await tester.pumpAndSettle();
      expect(pillGap(tester), closeTo(0, 0.5));
    });

    testWidgets('a rebuild that keeps the layout does not restart the morph', (
      tester,
    ) async {
      final flip = await pumpFlippable(tester);
      flip(LiquidGlassTabLayout.split);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final gaps = <double>[pillGap(tester)];
      for (var i = 0; i < 3; i++) {
        flip(LiquidGlassTabLayout.split);
        await tester.pump(const Duration(milliseconds: 40));
        gaps.add(pillGap(tester));
      }
      for (var i = 1; i < gaps.length; i++) {
        expect(gaps[i], greaterThanOrEqualTo(gaps[i - 1] - 0.5));
      }
      await tester.pumpAndSettle();
    });
  });
}

void _ignore(int _) {}
