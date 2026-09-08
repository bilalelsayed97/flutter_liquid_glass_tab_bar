import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const initial = LiquidGlassScrollGesture();

  test('accumulates frames that keep going the same way', () {
    final gesture = initial
        .extend(offset: 10, delta: 5)
        .extend(offset: 20, delta: 10)
        .extend(offset: 27, delta: 7);
    expect(gesture.travel, 22);
    expect(gesture.offset, 27);
  });

  test('accumulates upward travel as a negative run', () {
    final gesture = initial
        .extend(offset: 90, delta: -5)
        .extend(offset: 80, delta: -10);
    expect(gesture.travel, -15);
  });

  test('a direction change restarts the run rather than netting off', () {
    final gesture = initial
        .extend(offset: 100, delta: 30)
        .extend(offset: 70, delta: -30);
    expect(gesture.travel, -30);
  });

  test('a zero delta carries the run instead of breaking it', () {
    final gesture = initial
        .extend(offset: 100, delta: 20)
        .extend(offset: 100, delta: 0)
        .extend(offset: 110, delta: 10);
    expect(gesture.travel, 30);
  });

  test('reset forgets the run but keeps the position', () {
    final gesture = initial.extend(offset: 100, delta: 40).reset();
    expect(gesture.travel, 0);
    expect(gesture.offset, 100);
  });
}
