import 'package:flutter/widgets.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/split_bar_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(390, 48);
  const inset = GlassMorphGeometry.edgeInset;
  final contentWidth = size.width - 2 * inset;

  test('touching tab groups paint as one continuous capsule', () {
    final shape = GlassSplitBarShape(
      leadingWidth: contentWidth / 2,
      trailingWidth: contentWidth / 2,
      inset: inset,
    );
    final path = shape.getOuterPath(Offset.zero & size);

    expect(path.contains(size.center(Offset.zero)), isTrue);
    expect(path.contains(Offset(size.width / 2, 1)), isTrue);
  });

  test('glass joins before the tab geometry reaches its exact endpoint', () {
    final shape = GlassSplitBarShape(
      leadingWidth: (contentWidth - 32) / 2,
      trailingWidth: (contentWidth - 32) / 2,
      inset: inset,
    );
    expect(
      shape.getOuterPath(Offset.zero & size).contains(size.center(Offset.zero)),
      isTrue,
    );
  });

  test('connecting glass grows an organic neck before becoming flat', () {
    final shape = GlassSplitBarShape(
      leadingWidth: (contentWidth - 24) / 2,
      trailingWidth: (contentWidth - 24) / 2,
      inset: inset,
    );
    final path = shape.getOuterPath(Offset.zero & size);

    expect(path.contains(size.center(Offset.zero)), isTrue);
    expect(path.contains(Offset(size.width / 2, 1)), isFalse);
  });

  test('split glass covers only the two surviving pills', () {
    const pillWidth = GlassMorphGeometry.compactItemWidth;
    const shape = GlassSplitBarShape(
      leadingWidth: pillWidth,
      trailingWidth: pillWidth,
      inset: inset,
    );
    final path = shape.getOuterPath(Offset.zero & size);

    expect(
      path.contains(Offset(inset + pillWidth / 2, size.height / 2)),
      isTrue,
    );
    expect(path.contains(size.center(Offset.zero)), isFalse);
    expect(
      path.contains(
        Offset(size.width - inset - pillWidth / 2, size.height / 2),
      ),
      isTrue,
    );
  });

  test('asymmetric pills resolve to the text direction', () {
    const shape = GlassSplitBarShape(
      leadingWidth: 48,
      trailingWidth: 120,
      inset: inset,
    );
    final ltr = shape.getOuterPath(
      Offset.zero & size,
      textDirection: TextDirection.ltr,
    );
    final rtl = shape.getOuterPath(
      Offset.zero & size,
      textDirection: TextDirection.rtl,
    );
    // 100pt from the left: inside the wide pill only when it is on the left.
    final leftProbe = Offset(inset + 100, size.height / 2);
    final rightProbe = Offset(size.width - inset - 100, size.height / 2);
    expect(ltr.contains(leftProbe), isFalse);
    expect(ltr.contains(rightProbe), isTrue);
    expect(rtl.contains(leftProbe), isTrue);
    expect(rtl.contains(rightProbe), isFalse);
  });
}
