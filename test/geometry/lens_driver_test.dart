import 'package:flutter_liquid_glass_tab_bar/src/geometry/lens_driver.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const geometry = GlassMorphGeometry(
    width: 390,
    progress: 0,
    playerHeight: 56,
    labelBlockHeight: 16,
    showsLabels: true,
    itemCount: 4,
  );

  testWidgets('lens responds before the slower bar surface', (tester) async {
    final driver = GlassLensDriver(vsync: tester, committedIndex: 0);
    addTearDown(driver.dispose);

    driver.begin(
      coordinate: geometry.slotCenter(0),
      timeStamp: Duration.zero,
      geometry: geometry,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(driver.state.interactionAmount, greaterThan(driver.surfaceAmount));
    expect(driver.surfaceAmount, inExclusiveRange(0, 1));

    await tester.pump(const Duration(seconds: 1));
    expect(driver.state.interactionAmount, closeTo(1, 0.001));
    expect(driver.surfaceAmount, closeTo(1, 0.001));
  });

  testWidgets('reduce motion resolves both material channels immediately', (
    tester,
  ) async {
    final driver = GlassLensDriver(vsync: tester, committedIndex: 0)
      ..reduceMotion = true;
    addTearDown(driver.dispose);

    driver.begin(
      coordinate: geometry.slotCenter(0),
      timeStamp: Duration.zero,
      geometry: geometry,
    );
    expect(driver.state.interactionAmount, 1);
    expect(driver.surfaceAmount, 1);

    driver.cancel();
    expect(driver.state.interactionAmount, 0);
    expect(driver.surfaceAmount, 0);
  });

  testWidgets('resting tint returns only after lens settlement completes', (
    tester,
  ) async {
    final driver = GlassLensDriver(vsync: tester, committedIndex: 0);
    addTearDown(driver.dispose);
    expect(driver.isAtRest, isTrue);

    driver.begin(
      coordinate: geometry.slotCenter(0),
      timeStamp: Duration.zero,
      geometry: geometry,
    );
    driver.update(
      coordinate: geometry.slotCenter(1),
      timeStamp: const Duration(milliseconds: 100),
      geometry: geometry,
    );
    expect(driver.isAtRest, isFalse);

    driver.end(coordinate: geometry.slotCenter(1), geometry: geometry);
    expect(driver.isAtRest, isFalse);

    await tester.pumpAndSettle();
    expect(driver.isAtRest, isTrue);
  });
}
