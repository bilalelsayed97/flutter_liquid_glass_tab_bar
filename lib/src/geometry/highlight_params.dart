import 'package:flutter/foundation.dart';

/// Placement of the lens behind the selected tab, fully resolved by
/// `GlassHighlightPlacement` so widgets only position a box.
@immutable
class GlassHighlightParams {
  /// Offset from the bar's start edge.
  final double start;

  /// Width of the lens.
  final double width;

  /// Distance from the bar's bottom edge. The split layout lifts the pills
  /// to centre them against a taller card, and the lens travels with them.
  final double bottom;

  /// Height of the lens, already inset from the pill around it.
  final double height;

  /// Travel-derived deformation (`0` at a tab, `1` midway between tabs).
  final double travelStretch;

  /// Normalized logical velocity (`-1...1`) for asymmetric curvature/light.
  final double velocity;

  /// Press response (`0` idle, `1` pointer held).
  final double pressedAmount;

  /// Logical start-edge corner radius.
  final double startRadius;

  /// Logical end-edge corner radius.
  final double endRadius;

  /// Whether resting glass exists on the lens's logical start side.
  final bool connectsAtStart;

  /// Whether resting glass exists on the lens's logical end side.
  final bool connectsAtEnd;

  /// Creates a resolved placement.
  const GlassHighlightParams({
    required this.start,
    required this.width,
    required this.bottom,
    required this.height,
    required this.travelStretch,
    required this.velocity,
    required this.pressedAmount,
    required this.startRadius,
    required this.endRadius,
    required this.connectsAtStart,
    required this.connectsAtEnd,
  });
}
