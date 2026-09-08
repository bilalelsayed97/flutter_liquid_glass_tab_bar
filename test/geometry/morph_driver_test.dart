import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_driver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GlassMorphDriver build({bool split = false}) {
    final driver = GlassMorphDriver(vsync: const TestVSync(), split: split);
    addTearDown(driver.dispose);
    return driver;
  }

  testWidgets('starts at the endpoint it was built for', (tester) async {
    expect(build().progress.value, 0);
    expect(build(split: true).progress.value, 1);
  });

  testWidgets('settles exactly on its endpoints', (tester) async {
    final driver = build();
    driver.settleTo(split: true);
    await tester.pumpAndSettle();
    expect(driver.progress.value, 1);

    driver.settleTo(split: false);
    await tester.pumpAndSettle();
    expect(driver.progress.value, 0);
  });

  testWidgets('never leaves the 0..1 range', (tester) async {
    final driver = build();
    driver.settleTo(split: true);
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(driver.progress.value, inInclusiveRange(0, 1));
    }
  });

  testWidgets('a reversal mid-flight is continuous, not a jump', (
    tester,
  ) async {
    final driver = build();
    driver.settleTo(split: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final atReversal = driver.progress.value;
    expect(atReversal, inExclusiveRange(0, 1));

    driver.settleTo(split: false);
    await tester.pump();
    expect(driver.progress.value, closeTo(atReversal, 0.05));

    await tester.pumpAndSettle();
    expect(driver.progress.value, 0);
  });

  testWidgets('re-requesting the current layout while idle does nothing', (
    tester,
  ) async {
    final driver = build();
    driver.settleTo(split: true);
    await tester.pumpAndSettle();
    driver.settleTo(split: true);
    await tester.pump();
    expect(driver.progress.value, 1);
  });
}
