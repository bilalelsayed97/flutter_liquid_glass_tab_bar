import 'package:flutter_liquid_glass_tab_bar/src/geometry/active_surface_resolver.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_liquid_glass_tab_bar/src/theme/glass_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = GlassActiveSurfaceResolver();
  const geometry = GlassMorphGeometry(
    width: 390,
    progress: 0,
    playerHeight: 56,
    labelBlockHeight: 16,
    showsLabels: true,
    itemCount: 4,
  );

  test('shader interaction grows the real bar and material on both edges', () {
    final active = resolver.resolve(
      geometry: geometry,
      surfaceAmount: 1,
      supportsShader: true,
    );

    expect(active.expansion, GlassSpec.activeBarExpansion);
    expect(
      active.totalHeight - geometry.totalHeight,
      2 * GlassSpec.activeBarExpansion,
    );
    expect(
      active.materialHeight - geometry.pillHeight,
      2 * GlassSpec.activeBarExpansion,
    );
    expect(
      active.materialBottom,
      geometry.pillBottom - GlassSpec.activeBarExpansion,
    );
  });

  test('non-Impeller fallback keeps the stable resting geometry', () {
    final fallback = resolver.resolve(
      geometry: geometry,
      surfaceAmount: 1,
      supportsShader: false,
    );

    expect(fallback.expansion, 0);
    expect(fallback.totalHeight, geometry.totalHeight);
    expect(fallback.materialHeight, geometry.pillHeight);
    expect(fallback.materialBottom, geometry.pillBottom);
  });

  test('bar sizing follows the slow interaction timeline continuously', () {
    final halfway = resolver.resolve(
      geometry: geometry,
      surfaceAmount: 0.5,
      supportsShader: true,
    );
    expect(halfway.expansion, GlassSpec.activeBarExpansion * 0.5);
  });
}
