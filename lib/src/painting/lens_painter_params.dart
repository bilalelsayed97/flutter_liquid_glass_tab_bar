import 'package:flutter/widgets.dart';

/// Resolved theme, shape, and motion inputs for the selected glass lens.
@immutable
class GlassLensPainterParams {
  /// Corner radii of the lens.
  final BorderRadius borderRadius;

  /// Lens tint.
  final Color tint;

  /// Shadow and attenuation colour.
  final Color attenuation;

  /// Rim highlight colour.
  final Color rim;

  /// Specular highlight colour.
  final Color specular;

  /// Normalized velocity (`-1...1`).
  final double velocity;

  /// Press response (`0` idle, `1` held).
  final double pressedAmount;

  /// Creates the painter inputs.
  const GlassLensPainterParams({
    required this.borderRadius,
    required this.tint,
    required this.attenuation,
    required this.rim,
    required this.specular,
    required this.velocity,
    required this.pressedAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassLensPainterParams &&
          other.borderRadius == borderRadius &&
          other.tint == tint &&
          other.attenuation == attenuation &&
          other.rim == rim &&
          other.specular == specular &&
          other.velocity == velocity &&
          other.pressedAmount == pressedAmount;

  @override
  int get hashCode => Object.hash(
    borderRadius,
    tint,
    attenuation,
    rim,
    specular,
    velocity,
    pressedAmount,
  );
}
