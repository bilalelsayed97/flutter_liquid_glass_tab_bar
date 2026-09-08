import 'package:flutter/widgets.dart';

/// Resolved theme and geometry inputs for the outer glass painter.
@immutable
class GlassPainterParams {
  /// Outline of the material.
  final ShapeBorder shape;

  /// Material tint.
  final Color tint;

  /// Shadow and lower-edge attenuation colour.
  final Color attenuation;

  /// Rim highlight colour.
  final Color rim;

  /// Specular highlight colour.
  final Color specular;

  /// Direction the gradients resolve against.
  final TextDirection textDirection;

  /// Creates the painter inputs.
  const GlassPainterParams({
    required this.shape,
    required this.tint,
    required this.attenuation,
    required this.rim,
    required this.specular,
    required this.textDirection,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassPainterParams &&
          other.shape == shape &&
          other.tint == tint &&
          other.attenuation == attenuation &&
          other.rim == rim &&
          other.specular == specular &&
          other.textDirection == textDirection;

  @override
  int get hashCode =>
      Object.hash(shape, tint, attenuation, rim, specular, textDirection);
}
