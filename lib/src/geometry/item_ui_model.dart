import 'package:flutter/foundation.dart';

import '../model/tab_item.dart';

/// Ready-to-render data for one tab: what it is, where it sits, and how the
/// moving lens is emphasising it right now.
@immutable
class GlassItemUiModel {
  /// Index of the tab in the bar.
  final int index;

  /// The tab's glyphs and label.
  final LiquidGlassTabItem item;

  /// Whether this is the committed selection.
  final bool selected;

  /// Whether the tab stays visible when the bar splits.
  final bool persistsWhenCollapsed;

  /// Continuous visual emphasis from the moving lens (`0` inactive, `1`
  /// centred). Deliberately separate from the committed [selected].
  final double selectionInfluence;

  /// Creates one tab's render data.
  const GlassItemUiModel({
    required this.index,
    required this.item,
    required this.selected,
    required this.persistsWhenCollapsed,
    this.selectionInfluence = 0,
  });
}
