import 'package:flutter/widgets.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScrollController extends Mock implements ScrollController {}

void main() {
  late ValueNotifier<bool> hasCard;

  LiquidGlassTabController build({ValueChanged<int>? onTabSelected}) {
    final controller = LiquidGlassTabController(
      hasCard: hasCard,
      onTabSelected: onTabSelected,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(Curves.linear);
  });

  setUp(() {
    hasCard = ValueNotifier(true);
    addTearDown(hasCard.dispose);
  });

  /// Drives a real downward drag: the policy needs sustained travel.
  void scrollDown(LiquidGlassTabController controller, {double from = 400}) {
    for (var frame = 0; frame < 3; frame++) {
      controller.reportScroll(offset: from + frame * 20, delta: 20);
    }
  }

  group('selectIndex', () {
    test('switches tab, re-docks the bar and reports the switch', () {
      final selected = <int>[];
      final controller = build(onTabSelected: selected.add);
      scrollDown(controller, from: 500);
      expect(controller.layout, LiquidGlassTabLayout.split);

      controller.selectIndex(2);

      expect(controller.selectedIndex, 2);
      expect(controller.layout, LiquidGlassTabLayout.docked);
      expect(selected, [2]);
    });

    test('a switched-to tab starts with a clean travel budget', () {
      final controller = build();
      controller.reportScroll(offset: 500, delta: 20);
      controller.reportScroll(offset: 520, delta: 20);

      controller.selectIndex(2);
      controller.reportScroll(offset: 540, delta: 20);

      expect(controller.layout, LiquidGlassTabLayout.docked);
    });

    test('re-selecting the current tab scrolls it to the top instead', () {
      final selected = <int>[];
      final controller = build(onTabSelected: selected.add);
      final scroll = _MockScrollController();
      when(() => scroll.hasClients).thenReturn(true);
      when(() => scroll.offset).thenReturn(300);
      when(
        () => scroll.animateTo(
          any(),
          duration: any(named: 'duration'),
          curve: any(named: 'curve'),
        ),
      ).thenAnswer((_) async {});
      controller.registerScrollController(0, scroll);

      controller.selectIndex(0);

      expect(controller.selectedIndex, 0);
      expect(selected, isEmpty);
      verify(
        () => scroll.animateTo(
          0,
          duration: any(named: 'duration'),
          curve: any(named: 'curve'),
        ),
      ).called(1);
    });

    test('an unregistered controller is not scrolled', () {
      final controller = build();
      final scroll = _MockScrollController();
      controller.registerScrollController(0, scroll);
      controller.unregisterScrollController(0, scroll);

      controller.selectIndex(0);

      verifyZeroInteractions(scroll);
    });
  });

  group('reportScroll', () {
    test('splits the bar when the tab is scrolled down', () {
      final controller = build();
      scrollDown(controller);
      expect(controller.layout, LiquidGlassTabLayout.split);
    });

    test('one big frame is not enough on its own', () {
      final controller = build();
      controller.reportScroll(offset: 400, delta: 40);
      expect(controller.layout, LiquidGlassTabLayout.docked);
    });

    test('notifies only when the layout changes', () {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      scrollDown(controller);
      controller.reportScroll(offset: 460, delta: 20);
      controller.reportScroll(offset: 480, delta: 20);

      expect(notifications, 1);
    });

    test('stays docked while there is no card', () {
      hasCard.value = false;
      final controller = build();
      scrollDown(controller, from: 900);
      expect(controller.layout, LiquidGlassTabLayout.docked);
    });

    test('a null hasCard means the card is always present', () {
      final controller = LiquidGlassTabController();
      addTearDown(controller.dispose);
      scrollDown(controller);
      expect(controller.layout, LiquidGlassTabLayout.split);
    });
  });

  test('docks again when the card disappears', () {
    final controller = build();
    scrollDown(controller);
    expect(controller.layout, LiquidGlassTabLayout.split);

    hasCard.value = false;

    expect(controller.layout, LiquidGlassTabLayout.docked);
  });

  test('dock is a no-op while already docked', () {
    final controller = build();
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.dock();
    expect(notifications, 0);
  });
}
