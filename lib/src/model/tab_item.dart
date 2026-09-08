import 'package:flutter/widgets.dart';

/// One tab of a [LiquidGlassTabBar]: its glyphs and label.
///
/// Labels are plain strings so the bar stays localisation-agnostic — resolve
/// them with whatever your app uses and rebuild the list when the locale
/// changes.
@immutable
class LiquidGlassTabItem {
  /// Glyph shown while the tab is not selected.
  final IconData icon;

  /// Glyph shown while the tab is selected. Defaults to [icon].
  final IconData? selectedIcon;

  /// Label under the glyph in the docked layout.
  final String label;

  /// Screen-reader label. Defaults to [label].
  final String? semanticLabel;

  /// Creates a tab item.
  const LiquidGlassTabItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.semanticLabel,
  });

  /// The glyph for [selected].
  IconData iconFor({required bool selected}) =>
      selected ? (selectedIcon ?? icon) : icon;

  /// The label read aloud for this tab.
  String get resolvedSemanticLabel => semanticLabel ?? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassTabItem &&
          other.icon == icon &&
          other.selectedIcon == selectedIcon &&
          other.label == label &&
          other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(icon, selectedIcon, label, semanticLabel);
}
