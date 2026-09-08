import '../theme/glass_spec.dart';
import 'morph_geometry.dart';

/// Resolves the real bar expansion used by the shader path.
///
/// The material itself grows around a held tab; the effect is not simulated
/// with a border or a second overlay capsule.
class GlassActiveSurfaceResolver {
  /// Creates the stateless resolver.
  const GlassActiveSurfaceResolver();

  /// Returns parent and material bounds for the current interaction frame.
  ({
    double expansion,
    double totalHeight,
    double materialHeight,
    double materialBottom,
  })
  resolve({
    required GlassMorphGeometry geometry,
    required double surfaceAmount,
    required bool supportsShader,
  }) {
    final expansion = supportsShader
        ? GlassSpec.activeBarExpansion * surfaceAmount
        : 0.0;
    return (
      expansion: expansion,
      totalHeight: geometry.totalHeight + 2 * expansion,
      materialHeight: geometry.pillHeight + 2 * expansion,
      materialBottom: geometry.pillBottom - expansion,
    );
  }
}
