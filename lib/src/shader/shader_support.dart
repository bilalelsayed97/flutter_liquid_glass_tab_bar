import 'dart:ui';

/// Whether the current renderer can run the liquid-glass fragment shader as
/// a backdrop filter. True under Impeller; false on Skia, the web and in
/// `flutter test`, where the bar renders its blur-and-paint fallback.
abstract final class LiquidGlassShaderSupport {
  /// Whether `ImageFilter.shader` is available.
  static bool get isAvailable => ImageFilter.isShaderFilterSupported;
}
