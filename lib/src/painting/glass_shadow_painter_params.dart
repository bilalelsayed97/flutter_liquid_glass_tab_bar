import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Immutable inputs for the glass's bounded ambient shadow.
@immutable
class GlassShadowPainterParams {
  /// Outline that casts the shadow.
  final ShapeBorder shape;

  /// Shadow colour.
  final Color color;

  /// Shadow opacity.
  final double opacity;

  /// Direction the outline resolves against.
  final TextDirection textDirection;

  /// Creates the painter inputs.
  const GlassShadowPainterParams({
    required this.shape,
    required this.color,
    required this.opacity,
    required this.textDirection,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassShadowPainterParams &&
          other.shape == shape &&
          other.color == color &&
          other.opacity == opacity &&
          other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(shape, color, opacity, textDirection);
}
