import 'package:flutter/widgets.dart';

/// Measures the label block under a tab's glyph, so the bar's geometry can
/// *derive* the pill's height instead of reading it back off a laid-out pill.
///
/// Measuring the pill itself would be circular: the morph is what changes
/// the pill's height, so each reading would arrive a frame late. The label's
/// height depends only on the style and the text scaler, which change rarely
/// and never as a result of the morph.
class GlassPillMetrics {
  /// Gap between the glyph and its label.
  static const double labelGap = 2;

  /// Creates the stateless measurer.
  const GlassPillMetrics();

  /// Height of a tab's label block — the label's own line plus the gap above
  /// it — or `0` when labels are hidden at this text scale.
  ///
  /// [labelStyle] must already be merged the way `Text` merges it
  /// (`DefaultTextStyle.of(context).style.merge(...)`), or the ambient line
  /// height is missed and every pill comes out a few points short.
  double labelBlockHeight({
    required TextStyle labelStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required bool showsLabels,
  }) {
    if (!showsLabels) return 0;
    final painter = TextPainter(
      // Labels are single-line, so their height is a property of the style
      // rather than of the string.
      text: TextSpan(text: 'X', style: labelStyle),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return labelGap + height;
  }
}
