import 'dart:math' as math;

import '../theme/glass_spec.dart';
import 'morph_geometry.dart';

/// Pure coordinate, bounds, candidate, and release rules for the lens.
class GlassLensPositionResolver {
  /// Creates the stateless resolver.
  const GlassLensPositionResolver();

  /// Converts a start-edge bar coordinate into a continuous logical index.
  double positionOf({
    required GlassMorphGeometry geometry,
    required double coordinate,
  }) {
    final centres = [
      for (var index = 0; index < geometry.itemCount; index++)
        geometry.slotCenter(index),
    ];
    final firstGap = _nonZeroGap(centres, fromStart: true);
    final lastGap = _nonZeroGap(centres, fromStart: false);

    if (coordinate < centres.first) {
      return (coordinate - centres.first) /
          firstGap *
          GlassSpec.overscrollResistance;
    }
    if (coordinate > centres.last) {
      return geometry.itemCount -
          1 +
          (coordinate - centres.last) /
              lastGap *
              GlassSpec.overscrollResistance;
    }
    return _interpolatedPosition(coordinate, centres);
  }

  double _interpolatedPosition(double coordinate, List<double> centres) {
    for (var index = 0; index < centres.length - 1; index++) {
      final start = centres[index];
      final end = centres[index + 1];
      if (coordinate > end) continue;
      final span = end - start;
      if (span <= 0) return index.toDouble();
      return index + (coordinate - start) / span;
    }
    return (centres.length - 1).toDouble();
  }

  /// Converts a continuous logical index into a start-edge bar coordinate.
  double coordinateOf({
    required GlassMorphGeometry geometry,
    required double position,
  }) {
    final lastIndex = geometry.itemCount - 1;
    if (position <= 0) {
      return geometry.slotCenter(0) + position * _firstUsableGap(geometry);
    }
    if (position >= lastIndex) {
      return geometry.slotCenter(lastIndex) +
          (position - lastIndex) * _lastUsableGap(geometry);
    }
    final lower = position.floor();
    final upper = position.ceil();
    final fraction = position - lower;
    return geometry.slotCenter(lower) +
        (geometry.slotCenter(upper) - geometry.slotCenter(lower)) * fraction;
  }

  /// Width of the live slot under [position], before lens insets/stretch.
  double slotWidthAt({
    required GlassMorphGeometry geometry,
    required double position,
  }) {
    final clamped = position.clamp(0.0, geometry.itemCount - 1.0);
    final lower = clamped.floor();
    final upper = clamped.ceil();
    if (lower == upper) return geometry.slotWidth(lower);
    final fraction = clamped - lower;
    return geometry.slotWidth(lower) +
        (geometry.slotWidth(upper) - geometry.slotWidth(lower)) * fraction;
  }

  /// Closest selectable logical index to [position].
  int nearestSelectableIndex({
    required GlassMorphGeometry geometry,
    required double position,
  }) {
    var nearest = 0;
    var distance = double.infinity;
    for (var index = 0; index < geometry.itemCount; index++) {
      if (!geometry.isSelectable(index)) continue;
      final nextDistance = (position - index).abs();
      if (nextDistance >= distance) continue;
      nearest = index;
      distance = nextDistance;
    }
    return nearest;
  }

  /// Keeps [currentCandidate] until [position] firmly crosses the next slot.
  int candidateIndex({
    required GlassMorphGeometry geometry,
    required double position,
    required int currentCandidate,
  }) {
    final nearest = nearestSelectableIndex(
      geometry: geometry,
      position: position,
    );
    if (nearest == currentCandidate) return currentCandidate;
    final midpoint = (currentCandidate + nearest) / 2;
    final crossed = nearest > currentCandidate
        ? position >= midpoint + GlassSpec.candidateHysteresis
        : position <= midpoint - GlassSpec.candidateHysteresis;
    return crossed ? nearest : currentCandidate;
  }

  /// Release destination, allowing a directional flick to advance one tab.
  int releaseIndex({
    required GlassMorphGeometry geometry,
    required double position,
    required double velocity,
  }) {
    final nearest = nearestSelectableIndex(
      geometry: geometry,
      position: position,
    );
    if (velocity.abs() < GlassSpec.releaseVelocityThreshold) return nearest;
    final direction = velocity.sign.toInt();
    for (
      var index = nearest + direction;
      index >= 0 && index < geometry.itemCount;
      index += direction
    ) {
      if (geometry.isSelectable(index)) return index;
    }
    return nearest;
  }

  /// Continuous visual emphasis for one tab.
  double influenceOf({required double position, required int index}) =>
      (1 - (position - index).abs()).clamp(0.0, 1.0);

  double _firstUsableGap(GlassMorphGeometry geometry) =>
      _usableGap(geometry, 0, 1, step: 1);

  double _lastUsableGap(GlassMorphGeometry geometry) => _usableGap(
    geometry,
    geometry.itemCount - 1,
    geometry.itemCount - 2,
    step: -1,
  );

  double _usableGap(
    GlassMorphGeometry geometry,
    int anchor,
    int candidate, {
    required int step,
  }) {
    final anchorCentre = geometry.slotCenter(anchor);
    for (
      var index = candidate;
      index >= 0 && index < geometry.itemCount;
      index += step
    ) {
      final gap = (geometry.slotCenter(index) - anchorCentre).abs();
      if (gap > 0) return gap;
    }
    return math.max(geometry.slotWidth(anchor), 1);
  }

  double _nonZeroGap(List<double> centres, {required bool fromStart}) {
    final anchor = fromStart ? centres.first : centres.last;
    final indices = fromStart
        ? Iterable<int>.generate(centres.length - 1, (index) => index + 1)
        : Iterable<int>.generate(
            centres.length - 1,
            (index) => centres.length - 2 - index,
          );
    for (final index in indices) {
      final gap = (centres[index] - anchor).abs();
      if (gap > 0) return gap;
    }
    return 1;
  }
}
