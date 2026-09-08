import 'package:flutter/widgets.dart';

import '../theme/glass_spec.dart';
import 'glass_shadow_painter_params.dart';

/// Paints the faint displaced shadow that separates clear glass from content.
class GlassShadowPainter extends CustomPainter {
  /// Resolved inputs.
  final GlassShadowPainterParams params;

  /// Creates the painter.
  const GlassShadowPainter({required this.params});

  @override
  void paint(Canvas canvas, Size size) {
    final path = params.shape.getOuterPath(
      Offset.zero & size,
      textDirection: params.textDirection,
    );
    canvas.save();
    canvas.translate(0, GlassSpec.ambientShadowOffset);
    canvas.drawPath(
      path,
      Paint()
        ..color = params.color.withValues(alpha: params.opacity)
        ..maskFilter = const MaskFilter.blur(
          // An optical shadow belongs outside the glass; a normal blur would
          // also retain the filled path and darken the whole lens.
          BlurStyle.outer,
          GlassSpec.ambientShadowSigma,
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GlassShadowPainter oldDelegate) =>
      oldDelegate.params != params;
}
