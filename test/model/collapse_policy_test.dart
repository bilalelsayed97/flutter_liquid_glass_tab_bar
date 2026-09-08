import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = LiquidGlassCollapsePolicy();

  LiquidGlassTabLayout resolve({
    required double offset,
    required double travel,
    LiquidGlassTabLayout current = LiquidGlassTabLayout.docked,
    bool hasCard = true,
  }) => policy.resolve(
    gesture: LiquidGlassScrollGesture(offset: offset, travel: travel),
    current: current,
    hasCard: hasCard,
  );

  LiquidGlassTabLayout resolveFrames(
    List<double> deltas, {
    required double offset,
    LiquidGlassTabLayout current = LiquidGlassTabLayout.docked,
  }) {
    var gesture = const LiquidGlassScrollGesture();
    var layout = current;
    for (final delta in deltas) {
      gesture = gesture.extend(offset: offset, delta: delta);
      layout = policy.resolve(gesture: gesture, current: layout, hasCard: true);
    }
    return layout;
  }

  test('splits on sustained downward travel past the split offset', () {
    expect(
      resolve(offset: policy.splitOffset + 1, travel: policy.splitTravel),
      LiquidGlassTabLayout.split,
    );
  });

  test('re-docks on sustained upward travel', () {
    expect(
      resolve(
        offset: 400,
        travel: -policy.dockTravel,
        current: LiquidGlassTabLayout.split,
      ),
      LiquidGlassTabLayout.docked,
    );
  });

  test('always docks near the top of the list', () {
    expect(
      resolve(
        offset: policy.dockOffset,
        travel: 500,
        current: LiquidGlassTabLayout.split,
      ),
      LiquidGlassTabLayout.docked,
    );
  });

  test('never splits without a card to centre', () {
    expect(
      resolve(
        offset: 999,
        travel: 500,
        current: LiquidGlassTabLayout.split,
        hasCard: false,
      ),
      LiquidGlassTabLayout.docked,
    );
  });

  test('holds the current layout between the two offsets', () {
    final between = (policy.dockOffset + policy.splitOffset) / 2;
    expect(
      resolve(offset: between, travel: 500),
      LiquidGlassTabLayout.docked,
    );
    expect(
      resolve(
        offset: between,
        travel: 500,
        current: LiquidGlassTabLayout.split,
      ),
      LiquidGlassTabLayout.split,
    );
  });

  test('one frame of scroll never flips the layout', () {
    expect(resolveFrames([40], offset: 500), LiquidGlassTabLayout.docked);
  });

  test('a bouncing settle does not flip the layout', () {
    expect(
      resolveFrames([30, -30, 28, -26, 20, -18, 12, -10, 6, -4], offset: 500),
      LiquidGlassTabLayout.docked,
    );
  });

  test('a deliberate drag still splits promptly', () {
    expect(
      resolveFrames([20, 20, 20], offset: 500),
      LiquidGlassTabLayout.split,
    );
  });

  test('thresholds are tunable', () {
    const eager = LiquidGlassCollapsePolicy(
      splitOffset: 10,
      dockOffset: 5,
      splitTravel: 10,
    );
    expect(
      eager.resolve(
        gesture: const LiquidGlassScrollGesture(offset: 20, travel: 10),
        current: LiquidGlassTabLayout.docked,
        hasCard: true,
      ),
      LiquidGlassTabLayout.split,
    );
  });
}
