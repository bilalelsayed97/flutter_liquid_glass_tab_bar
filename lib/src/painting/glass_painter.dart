import 'package:flutter/widgets.dart';

import '../theme/glass_spec.dart';
import 'glass_painter_params.dart';

/// Paints the tint, uneven illumination, attenuation, and optical rim of the
/// parent navigation glass in one layer (non-Impeller fallback).
class GlassPainter extends CustomPainter {
  /// Resolved inputs.
  final GlassPainterParams params;

  /// Creates the painter.
  const GlassPainter({required this.params});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = params.shape.getOuterPath(
      rect,
      textDirection: params.textDirection,
    );
    _paintTint(canvas, path, rect);
    _paintSpecular(canvas, path, rect);
    _paintAttenuation(canvas, path, rect);
    _paintRim(canvas, path, rect);
    _paintLowerRim(canvas, path, rect);
  }

  void _paintTint(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
          colors: [
            params.tint.withValues(alpha: GlassSpec.parentTintOpacity),
            params.tint.withValues(alpha: GlassSpec.parentTintBottomOpacity),
          ],
        ).createShader(rect, textDirection: params.textDirection),
    );
  }

  void _paintSpecular(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: AlignmentDirectional.topStart,
          radius: GlassSpec.parentSpecularRadius,
          colors: [
            params.specular.withValues(alpha: GlassSpec.parentSpecularOpacity),
            params.specular.withValues(alpha: GlassSpec.transparentOpacity),
          ],
        ).createShader(rect, textDirection: params.textDirection),
    );
  }

  void _paintAttenuation(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
          colors: [
            params.attenuation.withValues(alpha: GlassSpec.transparentOpacity),
            params.attenuation.withValues(
              alpha: GlassSpec.parentAttenuationOpacity,
            ),
          ],
        ).createShader(rect, textDirection: params.textDirection),
    );
  }

  void _paintRim(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlassSpec.opticalStroke
        ..shader = LinearGradient(
          begin: AlignmentDirectional.bottomStart,
          end: AlignmentDirectional.topEnd,
          colors: [
            params.rim.withValues(alpha: GlassSpec.parentRimOpacity),
            params.rim.withValues(alpha: GlassSpec.parentRimMiddleOpacity),
            params.rim.withValues(
              alpha: GlassSpec.parentRimOpacity * GlassSpec.parentRimEndFactor,
            ),
          ],
          stops: GlassSpec.rimStops,
        ).createShader(rect, textDirection: params.textDirection),
    );
  }

  void _paintLowerRim(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlassSpec.opticalStroke
        ..shader = LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            params.attenuation.withValues(alpha: GlassSpec.transparentOpacity),
            params.attenuation.withValues(alpha: GlassSpec.lowerRimOpacity),
          ],
        ).createShader(rect, textDirection: params.textDirection),
    );
  }

  @override
  bool shouldRepaint(covariant GlassPainter oldDelegate) =>
      oldDelegate.params != params;
}
