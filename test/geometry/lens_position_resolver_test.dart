import 'dart:ui';

import 'package:flutter_liquid_glass_tab_bar/src/geometry/lens_position_resolver.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_liquid_glass_tab_bar/src/theme/glass_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = GlassLensPositionResolver();

  GlassMorphGeometry geometry(double progress, {int itemCount = 4}) =>
      GlassMorphGeometry(
        width: 390,
        progress: progress,
        playerHeight: 56,
        labelBlockHeight: 17,
        showsLabels: true,
        itemCount: itemCount,
      );

  test('round-trips every docked slot centre through a continuous index', () {
    for (final count in [2, 3, 4, 5, 6]) {
      final docked = geometry(0, itemCount: count);
      for (var index = 0; index < docked.itemCount; index++) {
        final coordinate = resolver.coordinateOf(
          geometry: docked,
          position: index.toDouble(),
        );
        expect(
          resolver.positionOf(geometry: docked, coordinate: coordinate),
          closeTo(index, 0.001),
        );
      }
    }
  });

  test('start-edge mapping keeps logical indexes identical in RTL', () {
    final docked = geometry(0);
    final logical = docked.slotCenter(1);
    final ltr = docked.startCoordinate(logical, TextDirection.ltr);
    final rtl = docked.startCoordinate(
      docked.width - logical,
      TextDirection.rtl,
    );
    expect(ltr, rtl);
  });

  test('applies soft resistance beyond both end slots', () {
    final docked = geometry(0);
    final firstGap = docked.slotCenter(1) - docked.slotCenter(0);
    final before = resolver.positionOf(
      geometry: docked,
      coordinate: docked.slotCenter(0) - firstGap,
    );
    expect(before, closeTo(-GlassSpec.overscrollResistance, 0.001));
  });

  test('split release ignores collapsed middle tabs', () {
    final split = geometry(1, itemCount: 5);
    expect(
      resolver.releaseIndex(geometry: split, position: 1.4, velocity: 0),
      0,
    );
    expect(
      resolver.releaseIndex(geometry: split, position: 2.6, velocity: 0),
      4,
    );
  });

  test('candidate changes only after crossing the hysteresis margin', () {
    final docked = geometry(0);
    expect(
      resolver.candidateIndex(
        geometry: docked,
        position: 0.59,
        currentCandidate: 0,
      ),
      0,
    );
    expect(
      resolver.candidateIndex(
        geometry: docked,
        position: 0.61,
        currentCandidate: 0,
      ),
      1,
    );
  });

  test('directional release advances at most one selectable tab', () {
    final docked = geometry(0);
    expect(
      resolver.releaseIndex(geometry: docked, position: 0.1, velocity: 4),
      1,
    );
    expect(
      resolver.releaseIndex(geometry: docked, position: 2.9, velocity: -4),
      2,
    );
  });

  test('selection influence crossfades between adjacent tabs', () {
    expect(resolver.influenceOf(position: 1.25, index: 1), 0.75);
    expect(resolver.influenceOf(position: 1.25, index: 2), 0.25);
    expect(resolver.influenceOf(position: 1.25, index: 3), 0);
  });
}
