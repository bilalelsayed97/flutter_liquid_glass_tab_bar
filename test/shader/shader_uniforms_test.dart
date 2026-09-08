import 'dart:ui';

import 'package:flutter_liquid_glass_tab_bar/src/shader/shader_surface_params.dart';
import 'package:flutter_liquid_glass_tab_bar/src/shader/shader_uniforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GlassShaderSurfaceParams params(TextDirection direction) =>
      GlassShaderSurfaceParams(
        leadingWidth: 120,
        trailingWidth: 179,
        outerInset: 16,
        restingHeight: 65,
        activeHeight: 73,
        lensStart: 20,
        lensBottom: 10,
        lensWidth: 86,
        lensHeight: 81,
        pressedAmount: 1,
        surfaceAmount: 0.75,
        velocity: 0.25,
        morphProgress: 0,
        textDirection: direction,
        tint: const Color(0x38E4E7EA),
        lensTint: const Color(0x0900AEEF),
        specular: const Color(0x29FFFFFF),
        attenuation: const Color(0x1C3B3028),
      );

  test(
    'the shader compiles and consumes the complete uniform contract',
    () async {
      // Inside the package's own tests the root package's assets carry no
      // `packages/` prefix; consumers use kLiquidGlassShaderAssetKey.
      final program = await FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
      final shader = program.fragmentShader();

      expect(
        GlassShaderUniforms.bind(
          shader: shader,
          surfaceSize: const Size(390, 93),
          globalOrigin: const Offset(0, 751),
          pixelScale: 3,
          params: params(TextDirection.ltr),
        ),
        GlassShaderUniforms.endUniform,
      );

      shader.dispose();
    },
  );

  test('RTL resolves lens start onto the physical shader axis', () {
    expect(
      GlassShaderUniforms.physicalLensLeft(
        surfaceWidth: 390,
        params: params(TextDirection.ltr),
      ),
      20,
    );
    expect(
      GlassShaderUniforms.physicalLensLeft(
        surfaceWidth: 390,
        params: params(TextDirection.rtl),
      ),
      284,
    );
  });

  test('RTL swaps the pill widths onto the physical axis', () {
    expect(
      GlassShaderUniforms.physicalLeftWidth(params(TextDirection.ltr)),
      120,
    );
    expect(
      GlassShaderUniforms.physicalRightWidth(params(TextDirection.ltr)),
      179,
    );
    expect(
      GlassShaderUniforms.physicalLeftWidth(params(TextDirection.rtl)),
      179,
    );
    expect(
      GlassShaderUniforms.physicalRightWidth(params(TextDirection.rtl)),
      120,
    );
  });
}
