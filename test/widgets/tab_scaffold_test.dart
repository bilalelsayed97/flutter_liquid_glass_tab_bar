import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_tab_bar.dart';

void main() {
  const items = [
    LiquidGlassTabItem(icon: Icons.home, label: 'Home'),
    LiquidGlassTabItem(icon: Icons.search, label: 'Search'),
    LiquidGlassTabItem(icon: Icons.settings, label: 'Settings'),
  ];

  testWidgets('builds tabs lazily, keeps visited ones alive and switches', (
    tester,
  ) async {
    final controller = LiquidGlassTabController();
    addTearDown(controller.dispose);
    final built = <int>[];

    await pumpTabBar(
      tester,
      LiquidGlassTabScaffold(
        controller: controller,
        items: items,
        tabBuilders: [
          for (var i = 0; i < items.length; i++)
            (context) {
              built.add(i);
              return Center(child: Text('Tab $i'));
            },
        ],
      ),
    );
    expect(built.toSet(), {0});
    expect(find.text('Tab 0'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, 1);
    expect(built.toSet(), {0, 1});
    expect(find.text('Tab 1'), findsOneWidget);
    // The first tab stays mounted in the IndexedStack.
    expect(find.text('Tab 0', skipOffstage: false), findsOneWidget);
  });

  testWidgets('scrolling a tab splits the bar and re-selecting scrolls up', (
    tester,
  ) async {
    final controller = LiquidGlassTabController();
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await pumpTabBar(
      tester,
      LiquidGlassTabScaffold(
        controller: controller,
        items: items,
        card: const SizedBox(height: 56),
        tabBuilders: [
          (context) => LiquidGlassTabScrollTarget(
            tabController: controller,
            scrollController: scroll,
            child: ListView.builder(
              controller: scroll,
              itemCount: 200,
              itemBuilder: (_, i) => SizedBox(height: 40, child: Text('$i')),
            ),
          ),
          (context) => const SizedBox(),
          (context) => const SizedBox(),
        ],
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(controller.layout, LiquidGlassTabLayout.split);
    expect(scroll.offset, greaterThan(0));

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
  });
}
