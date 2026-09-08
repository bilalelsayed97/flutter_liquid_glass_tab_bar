import 'package:flutter/foundation.dart';

/// The transient visual state of the independently moving selected-tab lens.
@immutable
class GlassLensState {
  /// Continuous logical tab position (`0` is the bar's start edge).
  final double position;

  /// Logical slots per second; positive travels toward a larger index.
  final double velocity;

  /// The selectable tab currently previewed by the lens.
  final int candidateIndex;

  /// Whether a pointer is currently pressing the bar.
  final bool pressed;

  /// Eased active-depth response (`0` resting, `1` fully engaged).
  final double interactionAmount;

  /// Whether that pointer has crossed touch slop and is moving the lens.
  final bool dragging;

  /// Creates one frame of lens state.
  const GlassLensState({
    required this.position,
    required this.velocity,
    required this.candidateIndex,
    required this.pressed,
    required this.interactionAmount,
    required this.dragging,
  });
}
