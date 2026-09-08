import 'package:flutter/widgets.dart';

import '../geometry/highlight_params.dart';

/// Geometry and colours for the persistent navigation-glass surface.
@immutable
class GlassSurfaceParams {
  /// Outline used by the fallback painters.
  final ShapeBorder shape;

  /// Height of the tab strip the glass fills.
  final double height;

  /// Height of the material before interactive expansion.
  final double restingHeight;

  /// Distance from the bar's bottom edge to the strip.
  final double bottom;

  /// Live width of the leading tab group.
  final double leadingWidth;

  /// Live width of the trailing tab group.
  final double trailingWidth;

  /// Horizontal breathing room between the glass and the available bounds.
  final double outerInset;

  /// Current dock-to-split morph progress.
  final double morphProgress;

  /// Slower interaction depth of the whole material.
  final double surfaceAmount;

  /// Current selected-lens geometry and motion.
  final GlassHighlightParams highlight;

  /// Tint for the complete material.
  final Color tint;

  /// Opacity the shader mixes [tint] in at.
  final double tintOpacity;

  /// Selected-pill tint, transparent whenever the lens is moving.
  final Color selectedPillTint;

  /// Shadow and lower attenuation colour.
  final Color attenuation;

  /// Rim and specular highlight colour.
  final Color specular;

  /// Creates the surface inputs for one frame.
  const GlassSurfaceParams({
    required this.shape,
    required this.height,
    required this.restingHeight,
    required this.bottom,
    required this.leadingWidth,
    required this.trailingWidth,
    required this.outerInset,
    required this.morphProgress,
    required this.surfaceAmount,
    required this.highlight,
    required this.tint,
    required this.tintOpacity,
    required this.selectedPillTint,
    required this.attenuation,
    required this.specular,
  });
}
