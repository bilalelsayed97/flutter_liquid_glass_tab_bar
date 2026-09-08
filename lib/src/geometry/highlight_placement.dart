import 'dart:math' as math;

import '../theme/glass_spec.dart';
import 'highlight_params.dart';
import 'lens_position_resolver.dart';
import 'lens_state.dart';
import 'morph_geometry.dart';

/// Resolves selected-lens geometry against the current dock ↔ split frame.
class GlassHighlightPlacement {
  static const GlassLensPositionResolver _positionResolver =
      GlassLensPositionResolver();

  /// Uniform gap between the lens and its slot on every edge.
  static const double inset = GlassSpec.lensInset;

  /// Creates the stateless placement resolver.
  const GlassHighlightPlacement();

  /// Placement for the current frame.
  GlassHighlightParams placementOf({
    required GlassMorphGeometry geometry,
    required GlassLensState lens,
  }) {
    final baseHeight = math.max(geometry.pillHeight - 2 * inset, 0.0);
    final clampedPosition = lens.position.clamp(0.0, geometry.itemCount - 1.0);
    final fraction = clampedPosition - clampedPosition.floor();
    final travelStretch = math.sin(math.pi * fraction).abs();
    final velocity = _normalizedVelocity(lens.velocity);
    final width = _lensWidth(
      geometry: geometry,
      position: clampedPosition,
      travelStretch: travelStretch,
      lens: lens,
    );
    final height = _lensHeight(
      baseHeight: baseHeight,
      pillHeight: geometry.pillHeight,
      travelStretch: travelStretch,
      interactionAmount: lens.interactionAmount,
    );
    final start = _lensStart(geometry, lens.position, width, velocity);
    final radius = height / 2;
    final tightening = radius * velocity.abs() * GlassSpec.cornerTightening;

    return GlassHighlightParams(
      start: start,
      width: width,
      bottom: geometry.pillBottom + inset + (baseHeight - height) / 2,
      height: height,
      travelStretch: travelStretch,
      velocity: velocity,
      pressedAmount: lens.interactionAmount,
      startRadius: velocity < 0 ? radius - tightening : radius,
      endRadius: velocity > 0 ? radius - tightening : radius,
      connectsAtStart: clampedPosition > 0,
      connectsAtEnd: clampedPosition < geometry.itemCount - 1,
    );
  }

  double _normalizedVelocity(double velocity) =>
      (velocity / GlassSpec.maximumVelocitySlotsPerSecond).clamp(-1.0, 1.0);

  double _lensWidth({
    required GlassMorphGeometry geometry,
    required double position,
    required double travelStretch,
    required GlassLensState lens,
  }) {
    final baseWidth = math.max(
      _positionResolver.slotWidthAt(geometry: geometry, position: position) -
          2 * inset,
      0,
    );
    final pressExpansion =
        lens.interactionAmount * GlassSpec.horizontalPressExpansion * baseWidth;
    final velocity = _normalizedVelocity(lens.velocity);
    return baseWidth +
        travelStretch * GlassSpec.lensTravelStretch +
        velocity.abs() * GlassSpec.lensVelocityStretch +
        pressExpansion;
  }

  double _lensHeight({
    required double baseHeight,
    required double pillHeight,
    required double travelStretch,
    required double interactionAmount,
  }) {
    final travelHeight =
        baseHeight * (1 + travelStretch * GlassSpec.verticalTravelExpansion);
    final restingHeight = math.min(travelHeight, pillHeight);
    final activeHeight =
        pillHeight + 2 * GlassSpec.lensInteractiveVerticalOverflow;
    return restingHeight + (activeHeight - restingHeight) * interactionAmount;
  }

  double _lensStart(
    GlassMorphGeometry geometry,
    double position,
    double width,
    double velocity,
  ) {
    final centre = _positionResolver.coordinateOf(
      geometry: geometry,
      position: position,
    );
    final unclamped =
        centre + velocity * GlassSpec.lensLeadingShift - width / 2;
    final minimum = geometry.slotStart(0) - GlassSpec.maximumOverscroll;
    final maximum =
        geometry.slotStart(geometry.itemCount - 1) +
        geometry.slotWidth(geometry.itemCount - 1) -
        width +
        GlassSpec.maximumOverscroll;
    return unclamped.clamp(minimum, maximum);
  }
}
