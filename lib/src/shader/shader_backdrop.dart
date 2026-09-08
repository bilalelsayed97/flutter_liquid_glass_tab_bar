import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'shader_surface_params.dart';
import 'shader_uniforms.dart';

/// Applies the single-pass navigation material to the live page backdrop.
///
/// The render object binds its root-space origin at paint time, then the
/// shader converts fragment coordinates into the filter's local geometry.
/// This keeps the material attached during safe-area, orientation, and
/// dock/split moves.
class GlassShaderBackdrop extends SingleChildRenderObjectWidget {
  /// Loaded fragment shader.
  final FragmentShader shader;

  /// Geometry and theme inputs for the current animation frame.
  final GlassShaderSurfaceParams params;

  /// Creates a backdrop-filter render layer driven by [shader].
  const GlassShaderBackdrop({
    super.key,
    required this.shader,
    required this.params,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderGlassShaderBackdrop(
        shader,
        params,
        MediaQuery.devicePixelRatioOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlassShaderBackdrop renderObject,
  ) {
    renderObject
      ..shader = shader
      ..params = params
      ..pixelScale = MediaQuery.devicePixelRatioOf(context);
  }
}

/// Paint-time implementation for [GlassShaderBackdrop].
class RenderGlassShaderBackdrop extends RenderProxyBox {
  FragmentShader _shader;
  GlassShaderSurfaceParams _params;
  double _pixelScale;
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();

  /// Creates the render layer with its initial shader and uniforms.
  RenderGlassShaderBackdrop(this._shader, this._params, this._pixelScale);

  /// Active fragment shader instance cached by `ShaderBuilder`.
  FragmentShader get shader => _shader;
  set shader(FragmentShader value) {
    if (identical(value, _shader)) return;
    _shader = value;
    markNeedsPaint();
  }

  /// Current resolved shader inputs.
  GlassShaderSurfaceParams get params => _params;
  set params(GlassShaderSurfaceParams value) {
    if (value == _params) return;
    _params = value;
    markNeedsPaint();
  }

  /// Physical pixels represented by one logical layout pixel.
  double get pixelScale => _pixelScale;
  set pixelScale(double value) {
    if (value == _pixelScale) return;
    _pixelScale = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    GlassShaderUniforms.bind(
      shader: shader,
      surfaceSize: size,
      globalOrigin: localToGlobal(Offset.zero),
      pixelScale: pixelScale,
      params: params,
    );
    // Both the filter and its layer are frame-local. Reusing and mutating the
    // layer lets retained rendering keep the previous bar geometry.
    final filterLayer = BackdropFilterLayer()
      ..filter = ImageFilter.shader(shader)
      ..blendMode = BlendMode.srcOver;
    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (clipContext, clipOffset) => clipContext.pushLayer(
        filterLayer,
        (filterContext, filterOffset) {
          final renderChild = child;
          if (renderChild != null) {
            filterContext.paintChild(renderChild, filterOffset);
          }
        },
        clipOffset,
      ),
      oldLayer: _clipLayer.layer,
    );
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    super.dispose();
  }
}
