import 'package:flutter/widgets.dart';

import '../geometry/item_ui_model.dart';

/// One tab item inside a pill.
@immutable
class GlassItemParams {
  /// Alpha an unselected tab's glyph and label are dimmed to.
  static const double unselectedAlpha = 0.85;

  /// Scale at zero lens influence.
  static const double inactiveScale = 0.96;

  /// Additional scale at full lens influence.
  static const double selectionScale = 0.08;

  /// What to render.
  final GlassItemUiModel item;

  /// Selects this tab from assistive technology. Touch selection is the
  /// pill's job, so this is the semantics action, not a tap handler.
  final VoidCallback onTap;

  /// Width the item occupies at the current morph progress.
  final double width;

  /// How much of the label's slot is still open.
  final double labelVisibility;

  /// How visible the label's text is.
  final double labelOpacity;

  /// How visible the whole item is — below `1` only for folding tabs.
  final double opacity;

  /// Colour at full lens influence.
  final Color activeColor;

  /// Colour at zero lens influence.
  final Color inactiveColor;

  /// Label style before the per-tab colour is applied.
  final TextStyle labelStyle;

  /// Creates the item inputs.
  const GlassItemParams({
    required this.item,
    required this.onTap,
    required this.width,
    required this.labelVisibility,
    required this.labelOpacity,
    required this.activeColor,
    required this.inactiveColor,
    required this.labelStyle,
    this.opacity = 1,
  });

  /// Whether the item is still on screen; a folded tab must not be offered
  /// to assistive technology either.
  bool get isInteractive => opacity > 0;

  /// Alpha to draw the glyph at: the selection dim, times the fold fade.
  /// Baked into the colour rather than an `Opacity` widget, which would
  /// force a `saveLayer` per item on every frame of the morph.
  double get iconAlpha =>
      (unselectedAlpha + (1 - unselectedAlpha) * item.selectionInfluence) *
      opacity;

  /// Alpha to draw the label at: the glyph's, times the label's own fade.
  double get labelAlpha => iconAlpha * labelOpacity;

  /// Glyph/label scale as the lens approaches this slot.
  double get visualScale =>
      inactiveScale + selectionScale * item.selectionInfluence;
}
