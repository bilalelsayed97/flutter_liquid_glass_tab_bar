import 'dart:math' as math;

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/widgets.dart';

import '../theme/glass_spec.dart';

/// The optical outline behind the two tab groups throughout the morph.
///
/// When both groups touch, one continuous path is returned so painting the
/// rim cannot leave a centre seam. Once the groups separate, the path becomes
/// two independent pills around the card. The pills may differ in width (an
/// odd tab count), so each side is given explicitly in logical terms and
/// resolved to left/right through the text direction.
class GlassSplitBarShape extends ShapeBorder {
  /// Width of the pill at the logical start of the bar.
  final double leadingWidth;

  /// Width of the pill at the logical end of the bar.
  final double trailingWidth;

  /// Distance from the bar's edges to the glass.
  final double inset;

  /// Corner radius large enough to always produce a capsule.
  static const double _pillRadius = 999;

  /// Full Figma-style corner smoothing.
  static const double _cornerSmoothing = 1;

  /// Creates the outline for one frame.
  const GlassSplitBarShape({
    required this.leadingWidth,
    required this.trailingWidth,
    required this.inset,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rtl = textDirection == TextDirection.rtl;
    final leftWidth = rtl ? trailingWidth : leadingWidth;
    final rightWidth = rtl ? leadingWidth : trailingWidth;
    final contentWidth = rect.width - 2 * inset;
    final outerRadius = math.min(_pillRadius, rect.height / 2);
    final rawGap = math.max(contentWidth - leftWidth - rightWidth, 0.0);
    if (rawGap <= GlassSpec.glassConnectionDistance) {
      // Both pills stretch to meet, each absorbing half the remaining gap.
      return _connectedPath(
        rect: rect,
        leftWidth: leftWidth + rawGap / 2,
        rightWidth: rightWidth + rawGap / 2,
        outerRadius: outerRadius,
        rawGap: rawGap,
      );
    }

    const attractionRange =
        GlassSpec.glassAttractionDistance - GlassSpec.glassConnectionDistance;
    final attractionProgress =
        ((rawGap - GlassSpec.glassConnectionDistance) / attractionRange).clamp(
          0.0,
          1.0,
        );
    final visibleGap = rawGap * _smoothStep(attractionProgress);
    // The attraction closes the gap from both sides equally.
    final growth = (rawGap - visibleGap) / 2;
    return _separatedPath(
      rect: rect,
      leftWidth: leftWidth + growth,
      rightWidth: rightWidth + growth,
      radius: outerRadius,
    );
  }

  Path _connectedPath({
    required Rect rect,
    required double leftWidth,
    required double rightWidth,
    required double outerRadius,
    required double rawGap,
  }) {
    final left = Rect.fromLTWH(
      rect.left + inset,
      rect.top,
      leftWidth,
      rect.height,
    );
    final right = Rect.fromLTWH(left.right, rect.top, rightWidth, rect.height);
    var path = Path.combine(
      PathOperation.union,
      _pillPath(left, radius: outerRadius),
      _pillPath(right, radius: outerRadius),
    );

    final connectionProgress = _easeInCubic(
      1 - rawGap / GlassSpec.glassConnectionDistance,
    );
    final bridgeHeight = rect.height * connectionProgress;
    if (bridgeHeight > 0) {
      final bridge = Rect.fromCenter(
        center: Offset(left.right, rect.center.dy),
        width: 2 * outerRadius,
        height: bridgeHeight,
      );
      final bridgeRadius = math.min(
        bridgeHeight / 2,
        outerRadius * (1 - connectionProgress),
      );
      path = Path.combine(
        PathOperation.union,
        path,
        _pillPath(bridge, radius: bridgeRadius),
      );
    }
    return path;
  }

  Path _separatedPath({
    required Rect rect,
    required double leftWidth,
    required double rightWidth,
    required double radius,
  }) {
    final left = Rect.fromLTWH(
      rect.left + inset,
      rect.top,
      leftWidth,
      rect.height,
    );
    final right = Rect.fromLTWH(
      rect.right - inset - rightWidth,
      rect.top,
      rightWidth,
      rect.height,
    );
    return Path()
      ..addPath(_pillPath(left, radius: radius), Offset.zero)
      ..addPath(_pillPath(right, radius: radius), Offset.zero);
  }

  double _smoothStep(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double _easeInCubic(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * t;
  }

  Path _pillPath(Rect rect, {required double radius}) => SmoothRectangleBorder(
    borderRadius: SmoothBorderRadius(
      cornerRadius: radius,
      cornerSmoothing: _cornerSmoothing,
    ),
  ).getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => GlassSplitBarShape(
    leadingWidth: leadingWidth * t,
    trailingWidth: trailingWidth * t,
    inset: inset * t,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassSplitBarShape &&
          other.leadingWidth == leadingWidth &&
          other.trailingWidth == trailingWidth &&
          other.inset == inset;

  @override
  int get hashCode => Object.hash(leadingWidth, trailingWidth, inset);
}
