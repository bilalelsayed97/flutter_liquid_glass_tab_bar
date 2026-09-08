import 'package:flutter/widgets.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a subtree outside the shell is not a tab', (tester) async {
    late bool isTab;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          isTab = LiquidGlassTabScope.isTab(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(isTab, isFalse);
  });

  testWidgets('a scoped subtree is a tab and knows which one', (tester) async {
    late LiquidGlassTabScope? scope;
    await tester.pumpWidget(
      LiquidGlassTabScope(
        index: 2,
        child: Builder(
          builder: (context) {
            scope = LiquidGlassTabScope.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(scope!.index, 2);
  });

  test('notifies dependents only when the index actually changes', () {
    const child = SizedBox.shrink();
    const first = LiquidGlassTabScope(index: 0, child: child);
    const second = LiquidGlassTabScope(index: 1, child: child);
    expect(second.updateShouldNotify(first), isTrue);
    expect(
      second.updateShouldNotify(
        const LiquidGlassTabScope(index: 1, child: child),
      ),
      isFalse,
    );
  });

  testWidgets('HiddenInTab shows its child only outside a tab', (
    tester,
  ) async {
    const chrome = SizedBox(key: ValueKey('chrome'));
    final finder = find.byKey(const ValueKey('chrome'));

    await tester.pumpWidget(const HiddenInTab(child: chrome));
    expect(finder, findsOneWidget);

    await tester.pumpWidget(
      const LiquidGlassTabScope(index: 0, child: HiddenInTab(child: chrome)),
    );
    expect(finder, findsNothing);
  });
}
