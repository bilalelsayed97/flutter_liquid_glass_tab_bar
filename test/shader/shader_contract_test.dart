import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the backend-agnostic sampling rule for the glass shader.
///
/// `flutter test` runs on Skia and never executes the fragment shader, so the
/// source itself is the only place this rule can be checked. See
/// `doc/android-liquid-glass-backdrop-flip-fix.md`.
void main() {
  final code = File('shaders/liquid_glass.frag')
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('the glass shader samples its backdrop without a GLES y-flip', () {
    expect(
      code.contains('IMPELLER_TARGET_OPENGLES'),
      isFalse,
      reason:
          'Since Flutter 3.46 Impeller stores render-to-texture backdrops '
          'top-down on Metal, Vulkan, and OpenGL ES alike. A '
          'IMPELLER_TARGET_OPENGLES y-flip double-flips GLES devices. Keep the '
          'sampling path backend-agnostic and the Flutter floor at 3.47+.',
    );
  });

  test('the shader declares the uniforms the Dart binder writes, in order', () {
    final uniforms = RegExp(
      r'uniform\s+\w+\s+(\w+);',
    ).allMatches(code).map((m) => m.group(1)).toList();
    expect(uniforms, [
      'uTextureSize',
      'uOrigin',
      'uSurfaceSize',
      'uBaseGeometry',
      'uLensGeometry',
      'uMotion',
      'uOptics',
      'uTint',
      'uSpecular',
      'uAttenuation',
      'uLensTint',
      'uRightGeometry',
      'uComponentGeometry',
      'uInteraction',
      'uPixelScale',
      'uBackdrop',
    ]);
  });
}
