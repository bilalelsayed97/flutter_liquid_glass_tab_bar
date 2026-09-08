import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import '../painting/glass_painter.dart';
import '../painting/glass_painter_params.dart';
import '../painting/glass_shadow_painter.dart';
import '../painting/glass_shadow_painter_params.dart';
import '../shader/shader_backdrop.dart';
import '../shader/shader_precache.dart';
import '../shader/shader_support.dart';
import '../shader/shader_surface_params.dart';
import '../theme/glass_spec.dart';
import 'glass_surface_params.dart';

/// Owns the bar's single optical material surface.
///
/// Impeller receives one fragment shader containing the base bar, selected
/// lens, resting-height history, neck, refraction, and shadow. Other
/// renderers keep a clipped blur and lightweight painted selection.
class GlassSurface extends StatelessWidget {
  /// Resolved geometry and colours for the current frame.
  final GlassSurfaceParams params;

  /// Creates one persistent navigation material.
  const GlassSurface({super.key, required this.params});

  @override
  Widget build(BuildContext context) => LiquidGlassShaderSupport.isAvailable
      ? _ImpellerShader(params: params)
      : _FallbackGlass(params: params);
}

class _ImpellerShader extends StatelessWidget {
  final GlassSurfaceParams params;

  const _ImpellerShader({required this.params});

  @override
  Widget build(BuildContext context) {
    const padding = GlassSpec.shaderOpticalPadding;
    final shaderParams = GlassShaderSurfaceParams(
      leadingWidth: params.leadingWidth,
      trailingWidth: params.trailingWidth,
      outerInset: params.outerInset,
      restingHeight: params.restingHeight,
      activeHeight: params.height,
      lensStart: params.highlight.start,
      lensBottom: params.highlight.bottom - params.bottom + padding,
      lensWidth: params.highlight.width,
      lensHeight: params.highlight.height,
      pressedAmount: params.highlight.pressedAmount,
      surfaceAmount: params.surfaceAmount,
      velocity: params.highlight.velocity,
      morphProgress: params.morphProgress,
      textDirection: Directionality.of(context),
      tint: params.tint.withValues(alpha: params.tintOpacity),
      lensTint: params.selectedPillTint.withValues(
        alpha: params.selectedPillTint.a * GlassSpec.lensTintOpacity,
      ),
      specular: params.specular.withValues(
        alpha: GlassSpec.shaderSpecularOpacity,
      ),
      attenuation: params.attenuation.withValues(
        alpha: GlassSpec.shaderAttenuationOpacity,
      ),
    );
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: params.bottom - padding,
      height: params.height + 2 * padding,
      child: RepaintBoundary(
        child: ShaderBuilder(
          assetKey: kLiquidGlassShaderAssetKey,
          (context, shader, _) => GlassShaderBackdrop(
            shader: shader,
            params: shaderParams,
            child: const SizedBox.expand(),
          ),
          // Shader loading is normally hidden by precaching. Keeping the
          // fallback here prevents a transparent flash if loading is delayed.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: padding),
            child: _FallbackMaterial(params: params),
          ),
        ),
      ),
    );
  }
}

class _FallbackGlass extends StatelessWidget {
  final GlassSurfaceParams params;

  const _FallbackGlass({required this.params});

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    start: 0,
    end: 0,
    bottom: params.bottom,
    height: params.height,
    child: RepaintBoundary(child: _FallbackMaterial(params: params)),
  );
}

class _FallbackMaterial extends StatelessWidget {
  final GlassSurfaceParams params;

  const _FallbackMaterial({required this.params});

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: GlassShadowPainter(
            params: GlassShadowPainterParams(
              shape: params.shape,
              color: params.attenuation,
              opacity: GlassSpec.ambientShadowOpacity,
              textDirection: textDirection,
            ),
          ),
        ),
        ClipPath(
          clipper: ShapeBorderClipper(
            shape: params.shape,
            textDirection: textDirection,
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassSpec.parentBlurSigma,
              sigmaY: GlassSpec.parentBlurSigma,
              tileMode: TileMode.repeated,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        CustomPaint(
          painter: GlassPainter(
            params: GlassPainterParams(
              shape: params.shape,
              tint: params.tint,
              attenuation: params.attenuation,
              rim: params.specular,
              specular: params.specular,
              textDirection: textDirection,
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}
