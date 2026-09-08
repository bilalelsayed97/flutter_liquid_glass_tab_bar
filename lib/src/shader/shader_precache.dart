import 'package:flutter_shaders/flutter_shaders.dart';

/// Asset key of the bundled fragment shader as seen by consuming apps.
const String kLiquidGlassShaderAssetKey =
    'packages/flutter_liquid_glass_tab_bar/shaders/liquid_glass.frag';

/// Compiles and caches the liquid-glass shader ahead of the first frame.
///
/// Call it in `main()` before `runApp`. Without it the bar shows its
/// fallback material until the shader finishes loading — a brief, graceful
/// swap, but a swap.
Future<void> precacheLiquidGlassShader() =>
    ShaderBuilder.precacheShader(kLiquidGlassShaderAssetKey);
