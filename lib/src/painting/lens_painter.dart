import 'package:flutter/widgets.dart';

import '../theme/glass_spec.dart';
import 'lens_painter_params.dart';

/// Paints the selected lens as a convex, directionally lit optical surface
/// (non-Impeller fallback).
class GlassLensPainter extends CustomPainter {
  /// Resolved inputs.
  final GlassLensPainterParams params;

  /// Creates the painter.
  const GlassLensPainter({required this.params});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = params.borderRadius.toRRect(rect);
    final velocity = params.velocity.clamp(-1.0, 1.0);
    final specularX =
        GlassSpec.lensSpecularCenterX +
        velocity * GlassSpec.specularVelocityShift;
    final visibility = 1 - params.pressedAmount;
    final rimOpacity = GlassSpec.lensRimOpacity * visibility;
    _paintTint(canvas, rrect, rect, visibility);
    _paintLuminosity(canvas, rrect, rect, visibility);
    _paintSpecular(canvas, rrect, rect, specularX, visibility);
    _paintAttenuation(canvas, rrect, rect, velocity, visibility);
    _paintRim(canvas, rrect, rect, velocity, rimOpacity);
    _paintLowerRim(canvas, rrect, rect, visibility);
  }

  void _paintTint(Canvas canvas, RRect rrect, Rect rect, double visibility) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            params.tint.withValues(
              alpha: params.tint.a * GlassSpec.lensTintOpacity * visibility,
            ),
            params.tint.withValues(
              alpha:
                  params.tint.a * GlassSpec.lensTintBottomOpacity * visibility,
            ),
          ],
        ).createShader(rect),
    );
  }

  void _paintLuminosity(
    Canvas canvas,
    RRect rrect,
    Rect rect,
    double visibility,
  ) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, GlassSpec.lensLuminosityCenterY),
          radius: GlassSpec.lensLuminosityRadius,
          colors: [
            params.specular.withValues(
              alpha: GlassSpec.lensLuminosityOpacity * visibility,
            ),
            params.specular.withValues(alpha: GlassSpec.transparentOpacity),
          ],
        ).createShader(rect),
    );
  }

  void _paintSpecular(
    Canvas canvas,
    RRect rrect,
    Rect rect,
    double specularX,
    double visibility,
  ) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(specularX, GlassSpec.lensSpecularCenterY),
          radius: GlassSpec.lensSpecularRadius,
          colors: [
            params.specular.withValues(
              alpha: GlassSpec.lensSpecularOpacity * visibility,
            ),
            params.specular.withValues(alpha: GlassSpec.transparentOpacity),
          ],
        ).createShader(rect),
    );
  }

  void _paintAttenuation(
    Canvas canvas,
    RRect rrect,
    Rect rect,
    double velocity,
    double visibility,
  ) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-velocity, GlassSpec.lensAttenuationBeginY),
          end: Alignment(velocity, GlassSpec.lensAttenuationEndY),
          colors: [
            params.attenuation.withValues(alpha: GlassSpec.transparentOpacity),
            params.attenuation.withValues(
              alpha: GlassSpec.lensAttenuationOpacity * visibility,
            ),
          ],
        ).createShader(rect),
    );
  }

  void _paintRim(
    Canvas canvas,
    RRect rrect,
    Rect rect,
    double velocity,
    double rimOpacity,
  ) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlassSpec.opticalStroke
        ..shader = LinearGradient(
          begin: Alignment(
            GlassSpec.lensRimBeginX + velocity * GlassSpec.lensRimVelocityShift,
            -1,
          ),
          end: Alignment(
            GlassSpec.lensRimEndX + velocity * GlassSpec.lensRimVelocityShift,
            1,
          ),
          colors: [
            params.rim.withValues(alpha: rimOpacity.clamp(0.0, 1.0)),
            params.rim.withValues(
              alpha:
                  GlassSpec.lensRimMiddleOpacity *
                  (rimOpacity / GlassSpec.lensRimOpacity),
            ),
            params.rim.withValues(
              alpha: rimOpacity * GlassSpec.lensRimEndFactor,
            ),
          ],
          stops: GlassSpec.rimStops,
        ).createShader(rect),
    );
  }

  void _paintLowerRim(
    Canvas canvas,
    RRect rrect,
    Rect rect,
    double visibility,
  ) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlassSpec.opticalStroke
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            params.attenuation.withValues(alpha: GlassSpec.transparentOpacity),
            params.attenuation.withValues(
              alpha: GlassSpec.lensLowerRimOpacity * visibility,
            ),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant GlassLensPainter oldDelegate) =>
      oldDelegate.params != params;
}
