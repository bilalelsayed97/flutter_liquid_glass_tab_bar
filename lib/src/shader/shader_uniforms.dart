import 'dart:ui';

import 'package:flutter_shaders/flutter_shaders.dart';

import '../theme/glass_spec.dart';
import 'shader_surface_params.dart';

/// Binds Flutter geometry to the fragment-shader uniform contract.
///
/// `ImageFilter.shader` reserves float indexes zero and one for its input
/// texture size, so app-owned uniforms start at index two. The order here
/// must match the `uniform` declarations in `shaders/liquid_glass.frag`.
abstract final class GlassShaderUniforms {
  /// First float index available after the engine-owned texture size.
  static const int firstAppUniform = 2;

  /// Number of float slots occupied after all uniforms are bound.
  static const int endUniform = 51;

  /// Writes one complete shader frame and returns the next unused index.
  static int bind({
    required FragmentShader shader,
    required Size surfaceSize,
    required Offset globalOrigin,
    required double pixelScale,
    required GlassShaderSurfaceParams params,
  }) {
    final lensLeft = physicalLensLeft(
      surfaceWidth: surfaceSize.width,
      params: params,
    );
    final nextUniform = shader.setFloatUniforms(
      initialIndex: firstAppUniform,
      (uniforms) => uniforms
        ..setOffset(globalOrigin)
        ..setSize(surfaceSize)
        ..setFloats([
          params.outerInset,
          physicalLeftWidth(params),
          params.restingHeight,
          params.activeHeight,
        ])
        ..setFloats([
          lensLeft,
          params.lensBottom,
          params.lensWidth,
          params.lensHeight,
        ])
        ..setFloats([
          params.pressedAmount,
          params.surfaceAmount,
          params.velocity,
          params.morphProgress,
        ])
        ..setFloats([
          GlassSpec.shaderDisplacement,
          GlassSpec.shaderChromaticShift,
          GlassSpec.shaderSaturation,
          GlassSpec.shaderBarBlurRadius,
        ])
        ..setColor(params.tint)
        ..setColor(params.specular)
        ..setColor(params.attenuation)
        ..setColor(params.lensTint)
        ..setFloats([physicalRightWidth(params), 0, 0, 0])
        // Component geometry and interaction: unused by the navigation
        // path, zero-filled so the shader's component branch stays inert.
        ..setFloats([0, 0, 0, 0])
        ..setFloats([0, 0, 0, 0])
        ..setFloat(pixelScale),
    );
    assert(nextUniform == endUniform);
    return nextUniform;
  }

  /// Resolves the logical lens start to the shader's physical left axis.
  static double physicalLensLeft({
    required double surfaceWidth,
    required GlassShaderSurfaceParams params,
  }) => params.textDirection == TextDirection.ltr
      ? params.lensStart
      : surfaceWidth - params.lensStart - params.lensWidth;

  /// Width of the pill on the physical left.
  static double physicalLeftWidth(GlassShaderSurfaceParams params) =>
      params.textDirection == TextDirection.ltr
      ? params.leadingWidth
      : params.trailingWidth;

  /// Width of the pill on the physical right.
  static double physicalRightWidth(GlassShaderSurfaceParams params) =>
      params.textDirection == TextDirection.ltr
      ? params.trailingWidth
      : params.leadingWidth;
}
