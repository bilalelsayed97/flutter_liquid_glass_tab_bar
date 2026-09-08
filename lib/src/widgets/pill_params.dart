import 'package:flutter/widgets.dart';

import '../geometry/item_ui_model.dart';
import '../geometry/tab_group.dart';

/// One half of the bar: the tab items of one group.
@immutable
class GlassPillParams {
  /// The items this pill renders, in bar order.
  final List<GlassItemUiModel> items;

  /// Called with the tapped tab index.
  final ValueChanged<int> onSelect;

  /// Arms the lens press and records the pointer-to-lens grab offset.
  final ValueChanged<PointerDownEvent>? onPointerDown;

  /// Carries absolute pointer position plus a timestamp for lens motion.
  final ValueChanged<PointerMoveEvent>? onPointerMove;

  /// Supplies the release position and timestamp used to resolve the target.
  final ValueChanged<PointerUpEvent>? onPointerUp;

  /// Rolls a cancelled interaction back to the committed tab.
  final VoidCallback? onPointerCancel;

  /// Which end of the bar this pill sits at.
  final GlassTabGroup group;

  /// Width of the pill at the current morph progress.
  final double pillWidth;

  /// Distance from the bar's bottom edge to the pill.
  final double bottom;

  /// Height of the pill's glass at the current morph progress. Imposed
  /// rather than intrinsic so the glyphs stay centred in the glass.
  final double height;

  /// Width of a tab that stays visible when the bar splits.
  final double itemWidth;

  /// Width of a tab that folds away when the bar splits.
  final double collapsingItemWidth;

  /// How visible a folding tab is at the current progress.
  final double collapsingOpacity;

  /// How much of each label's slot is still open.
  final double labelVisibility;

  /// How visible the item labels are.
  final double labelOpacity;

  /// Colour at full lens influence.
  final Color activeColor;

  /// Colour at zero lens influence.
  final Color inactiveColor;

  /// Label style before the per-tab colour is applied.
  final TextStyle labelStyle;

  /// Creates the pill inputs.
  const GlassPillParams({
    required this.items,
    required this.onSelect,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    required this.group,
    required this.pillWidth,
    required this.bottom,
    required this.height,
    required this.itemWidth,
    required this.collapsingItemWidth,
    required this.collapsingOpacity,
    required this.labelVisibility,
    required this.labelOpacity,
    required this.activeColor,
    required this.inactiveColor,
    required this.labelStyle,
  });
}
