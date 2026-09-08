import 'package:flutter/widgets.dart';

/// Reads the laid-out height of a keyed subtree.
///
/// The card's height grows with text scale and with whatever it shows, so
/// the bar measures it rather than hardcoding a height that clips.
class GlassWidgetHeightReader {
  /// Creates the stateless reader.
  const GlassWidgetHeightReader();

  /// Height of [key]'s subtree, or `null` when it is not laid out yet.
  double? heightOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.size.height;
  }

  /// Whether [next] differs from [current] by enough to be worth a rebuild.
  bool changed(double current, double next) => (current - next).abs() > 0.5;
}
