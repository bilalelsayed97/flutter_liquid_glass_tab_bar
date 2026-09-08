import 'package:flutter/widgets.dart';

import '../geometry/highlight_params.dart';
import '../painting/glass_shadow_painter.dart';
import '../painting/glass_shadow_painter_params.dart';
import '../painting/lens_painter.dart';
import '../painting/lens_painter_params.dart';
import '../theme/glass_spec.dart';

/// Non-Impeller selected-tab lens.
///
/// Impeller renders the lens inside the bar's fragment shader; this painter
/// remains for renderers that cannot run shader filters.
class GlassSelectionHighlight extends StatelessWidget {
  /// Resolved placement.
  final GlassHighlightParams params;

  /// Lens tint.
  final Color tint;

  /// Shadow and attenuation colour.
  final Color attenuation;

  /// Rim and specular colour.
  final Color specular;

  /// Creates the fallback lens.
  const GlassSelectionHighlight({
    super.key,
    required this.params,
    required this.tint,
    required this.attenuation,
    required this.specular,
  });

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final borderRadius = BorderRadiusDirectional.only(
      topStart: Radius.circular(params.startRadius),
      bottomStart: Radius.circular(params.startRadius),
      topEnd: Radius.circular(params.endRadius),
      bottomEnd: Radius.circular(params.endRadius),
    ).resolve(textDirection);
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);
    return PositionedDirectional(
      start: params.start,
      width: params.width,
      bottom: params.bottom,
      height: params.height,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: GlassShadowPainter(
                params: GlassShadowPainterParams(
                  shape: shape,
                  color: attenuation,
                  opacity:
                      GlassSpec.lensShadowOpacity * (1 - params.pressedAmount),
                  textDirection: textDirection,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(
                painter: GlassLensPainter(
                  params: GlassLensPainterParams(
                    borderRadius: borderRadius,
                    tint: tint,
                    attenuation: attenuation,
                    rim: specular,
                    specular: specular,
                    velocity: params.velocity,
                    pressedAmount: 0,
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
