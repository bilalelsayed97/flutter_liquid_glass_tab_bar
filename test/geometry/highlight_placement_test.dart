import 'package:flutter_liquid_glass_tab_bar/src/geometry/highlight_placement.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/lens_state.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_liquid_glass_tab_bar/src/theme/glass_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placement = GlassHighlightPlacement();
  const geometry = GlassMorphGeometry(
    width: 390,
    progress: 0,
    playerHeight: 56,
    labelBlockHeight: 17,
    showsLabels: true,
    itemCount: 4,
  );

  GlassLensState lens({
    required double position,
    double velocity = 0,
    bool pressed = false,
  }) => GlassLensState(
    position: position,
    velocity: velocity,
    candidateIndex: position.round().clamp(0, 3),
    pressed: pressed,
    interactionAmount: pressed ? 1 : 0,
    dragging: velocity != 0,
  );

  test('resting lens is inset from its slot and vertically centred', () {
    final result = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1),
    );
    expect(result.width, lessThan(geometry.slotWidth(1)));
    expect(result.height, lessThan(geometry.pillHeight));
    expect(result.startRadius, closeTo(result.height / 2, 0.001));
    expect(
      result.start - geometry.slotStart(1),
      closeTo(GlassSpec.lensInset, 0.001),
    );
    expect(
      result.bottom - geometry.pillBottom,
      closeTo(GlassSpec.lensInset, 0.001),
    );
  });

  test('first and last lenses keep the same outer inset', () {
    for (final index in <int>[0, 3]) {
      final result = placement.placementOf(
        geometry: geometry,
        lens: lens(position: index.toDouble()),
      );
      final outerGap = index == 0
          ? result.start - GlassMorphGeometry.edgeInset
          : geometry.width -
                GlassMorphGeometry.edgeInset -
                result.start -
                result.width;
      expect(outerGap, closeTo(GlassSpec.lensInset, 0.001));
    }
  });

  test('lens stretches in both axes midway between tabs', () {
    final resting = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1),
    );
    final travelling = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1.5),
    );
    expect(travelling.width, greaterThan(resting.width));
    expect(travelling.height, greaterThan(resting.height));
    expect(travelling.travelStretch, closeTo(1, 0.001));
  });

  test('press response expands in both axes', () {
    final resting = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1),
    );
    final pressed = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1, pressed: true),
    );
    expect(pressed.width, greaterThan(resting.width));
    expect(
      pressed.height,
      closeTo(
        geometry.pillHeight + 2 * GlassSpec.lensInteractiveVerticalOverflow,
        0.001,
      ),
    );
  });

  test('positive velocity tightens only the logical leading edge', () {
    final moving = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1.25, velocity: 4),
    );
    expect(moving.endRadius, lessThan(moving.startRadius));
  });

  test('extreme pointer velocity stays within deformation limits', () {
    final moving = placement.placementOf(
      geometry: geometry,
      lens: lens(position: 1.25, velocity: 100),
    );
    expect(moving.velocity, 1);
    expect(
      moving.start,
      greaterThanOrEqualTo(
        geometry.slotStart(0) - GlassSpec.maximumOverscroll,
      ),
    );
  });
}
