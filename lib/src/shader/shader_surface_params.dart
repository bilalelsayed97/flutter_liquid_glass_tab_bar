import 'package:flutter/widgets.dart';

/// Fully resolved geometry and theme inputs for one shader frame.
///
/// Callers supply logical start-edge geometry; the binder resolves it to the
/// shader's physical left axis through [textDirection].
@immutable
class GlassShaderSurfaceParams {
  /// Width of the pill at the bar's logical start.
  final double leadingWidth;

  /// Width of the pill at the bar's logical end.
  final double trailingWidth;

  /// Horizontal inset of the material from the available bounds.
  final double outerInset;

  /// Resting height retained optically inside the active lens.
  final double restingHeight;

  /// Current height, including interactive expansion.
  final double activeHeight;

  /// Logical start position of the lens.
  final double lensStart;

  /// Distance from the visible bar bottom to the lens bottom.
  final double lensBottom;

  /// Current lens width.
  final double lensWidth;

  /// Current lens height.
  final double lensHeight;

  /// Press/drag depth from zero to one.
  final double pressedAmount;

  /// Slower expansion depth of the parent surface.
  final double surfaceAmount;

  /// Normalized horizontal lens velocity from minus one to one.
  final double velocity;

  /// Dock-to-split morph progress from zero to one.
  final double morphProgress;

  /// Text direction used to resolve logical coordinates.
  final TextDirection textDirection;

  /// Material tint, alpha already resolved.
  final Color tint;

  /// Lens tint, alpha already resolved for the current motion.
  final Color lensTint;

  /// Highlight colour, alpha already resolved.
  final Color specular;

  /// Shadow and lower attenuation colour, alpha already resolved.
  final Color attenuation;

  /// Creates resolved inputs for one shader frame.
  const GlassShaderSurfaceParams({
    required this.leadingWidth,
    required this.trailingWidth,
    required this.outerInset,
    required this.restingHeight,
    required this.activeHeight,
    required this.lensStart,
    required this.lensBottom,
    required this.lensWidth,
    required this.lensHeight,
    required this.pressedAmount,
    required this.surfaceAmount,
    required this.velocity,
    required this.morphProgress,
    required this.textDirection,
    required this.tint,
    required this.lensTint,
    required this.specular,
    required this.attenuation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassShaderSurfaceParams &&
          other.leadingWidth == leadingWidth &&
          other.trailingWidth == trailingWidth &&
          other.outerInset == outerInset &&
          other.restingHeight == restingHeight &&
          other.activeHeight == activeHeight &&
          other.lensStart == lensStart &&
          other.lensBottom == lensBottom &&
          other.lensWidth == lensWidth &&
          other.lensHeight == lensHeight &&
          other.pressedAmount == pressedAmount &&
          other.surfaceAmount == surfaceAmount &&
          other.velocity == velocity &&
          other.morphProgress == morphProgress &&
          other.textDirection == textDirection &&
          other.tint == tint &&
          other.lensTint == lensTint &&
          other.specular == specular &&
          other.attenuation == attenuation;

  @override
  int get hashCode => Object.hash(
    leadingWidth,
    trailingWidth,
    outerInset,
    restingHeight,
    activeHeight,
    lensStart,
    lensBottom,
    lensWidth,
    lensHeight,
    pressedAmount,
    surfaceAmount,
    velocity,
    morphProgress,
    textDirection,
    tint,
    lensTint,
    specular,
    attenuation,
  );
}
