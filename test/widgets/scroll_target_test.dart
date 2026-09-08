import 'package:flutter/widgets.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registers the enclosing tab and scrolls it to the top', (
    tester,
  ) async {
    final controller = LiquidGlassTabController(initialIndex: 1);
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidGlassTabScope(
          index: 1,
          child: LiquidGlassTabScrollTarget(
            tabController: controller,
            scrollController: scroll,
            child: ListView.builder(
              controller: scroll,
              itemCount: 100,
              itemBuilder: (_, i) => SizedBox(height: 50, child: Text('$i')),
            ),
          ),
        ),
      ),
    );
    scroll.jumpTo(800);
    await tester.pump();

    controller.selectIndex(1);
    await tester.pumpAndSettle();

    expect(scroll.offset, 0);
  });

  testWidgets('unregisters on dispose', (tester) async {
    final controller = LiquidGlassTabController();
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidGlassTabScope(
          index: 0,
          child: LiquidGlassTabScrollTarget(
            tabController: controller,
            scrollController: scroll,
            child: ListView(
              controller: scroll,
              children: const [SizedBox(height: 5000)],
            ),
          ),
        ),
      ),
    );
    scroll.jumpTo(800);
    await tester.pumpWidget(const SizedBox.shrink());

    // Nothing is registered any more, so nothing animates and nothing throws.
    controller.selectIndex(0);
    await tester.pump();
  });
}
