import 'package:flutter_liquid_glass_tab_bar/src/geometry/morph_geometry.dart';
import 'package:flutter_liquid_glass_tab_bar/src/geometry/tab_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const width = 390.0;
  const playerHeight = 56.0;
  const labelBlockHeight = 17.0;

  GlassMorphGeometry geometry(
    double progress, {
    bool showsLabels = true,
    double player = playerHeight,
    int itemCount = 4,
  }) => GlassMorphGeometry(
    width: width,
    progress: progress,
    playerHeight: player,
    labelBlockHeight: labelBlockHeight,
    showsLabels: showsLabels,
    itemCount: itemCount,
  );

  group('docked', () {
    final docked = geometry(0);

    test('the two pills exactly fill the width between the edge insets', () {
      expect(
        docked.leadingPillWidth + docked.trailingPillWidth,
        closeTo(width - 2 * GlassMorphGeometry.edgeInset, 0.001),
      );
    });

    test('the card spans the full width and sits above the pills', () {
      expect(docked.playerStart, 0);
      expect(docked.playerEnd, 0);
      expect(docked.playerWidth, width);
      expect(docked.playerBottom, docked.dockedPillHeight);
    });

    test('height stacks the card on the pills', () {
      expect(docked.totalHeight, playerHeight + docked.dockedPillHeight);
    });

    test('labels are fully visible', () {
      expect(docked.labelOpacity, 1);
      expect(docked.labelVisibility, 1);
    });
  });

  group('split', () {
    final split = geometry(1);

    test('each pill keeps one icon-only tab and folds the other away', () {
      expect(split.itemWidth, GlassMorphGeometry.compactItemWidth);
      expect(split.collapsingItemWidth, 0);
      expect(split.leadingPillWidth, GlassMorphGeometry.compactItemWidth);
      expect(split.trailingPillWidth, GlassMorphGeometry.compactItemWidth);
    });

    test('the card takes the gap between the two pills', () {
      expect(
        split.playerStart,
        split.leadingPillWidth + GlassMorphGeometry.gap,
      );
      expect(split.playerWidth, width - split.playerStart - split.playerEnd);
    });

    test('height collapses to a single row', () {
      expect(split.totalHeight, split.splitPillHeight);
    });
  });

  group('pill height', () {
    test('is driven by the label block, not measured', () {
      expect(geometry(0).dockedPillHeight, greaterThan(48));
      expect(geometry(0).splitPillHeight, 48);
    });

    test('never drops below the minimum touch target', () {
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(geometry(progress).pillHeight, greaterThanOrEqualTo(48));
      }
    });

    test('keeps the 65pt docked material even when labels are hidden', () {
      final cramped = geometry(0, showsLabels: false);
      expect(cramped.dockedPillHeight, 65);
      expect(geometry(0.5, showsLabels: false).pillHeight, 56.5);
    });
  });

  group('progress guards', () {
    test('stays docked while there is no card, whatever was asked for', () {
      final empty = geometry(1, player: 0);
      expect(empty.progress, 0);
      expect(empty.totalHeight, empty.dockedPillHeight);
    });

    test('clamps out-of-range progress rather than extrapolating', () {
      expect(geometry(1.4).progress, 1);
      expect(geometry(-0.2).progress, 0);
    });

    test('tab widths never go negative, at any requested progress', () {
      for (final progress in [-0.5, 0.0, 0.5, 1.0, 1.5]) {
        expect(geometry(progress).collapsingItemWidth, greaterThanOrEqualTo(0));
        expect(geometry(progress).itemWidth, greaterThanOrEqualTo(0));
      }
    });
  });

  group('any tab count from 2 to 6', () {
    for (final count in [2, 3, 4, 5, 6]) {
      group('$count tabs', () {
        test('only the first and last tabs persist', () {
          final g = geometry(1, itemCount: count);
          for (var index = 0; index < count; index++) {
            expect(
              g.persistsWhenCollapsed(index),
              index == 0 || index == count - 1,
            );
          }
        });

        test('the first half leads and the rest trails', () {
          final g = geometry(0, itemCount: count);
          expect(g.leadingCount + g.trailingCount, count);
          expect(g.leadingCount, count ~/ 2);
          for (var index = 0; index < count; index++) {
            expect(
              g.groupOf(index),
              index < count ~/ 2
                  ? GlassTabGroup.leading
                  : GlassTabGroup.trailing,
            );
          }
        });

        test('docked pills fill the content width with equal slots', () {
          final g = geometry(0, itemCount: count);
          const content = width - 2 * GlassMorphGeometry.edgeInset;
          expect(
            g.leadingPillWidth + g.trailingPillWidth,
            closeTo(content, 0.001),
          );
          for (var index = 0; index < count; index++) {
            expect(g.slotWidth(index), closeTo(content / count, 0.001));
          }
        });

        test('split pills are both one compact tab wide', () {
          final g = geometry(1, itemCount: count);
          expect(g.leadingPillWidth, GlassMorphGeometry.compactItemWidth);
          expect(g.trailingPillWidth, GlassMorphGeometry.compactItemWidth);
          expect(g.playerStart, g.playerEnd);
        });

        test('slots tile each pill without gaps, at every progress', () {
          for (final progress in [0.0, 0.3, 0.7, 1.0]) {
            final g = geometry(progress, itemCount: count);
            for (var index = 1; index < g.leadingCount; index++) {
              expect(
                g.slotStart(index),
                closeTo(g.slotStart(index - 1) + g.slotWidth(index - 1), 0.001),
              );
            }
            for (var index = g.leadingCount + 1; index < count; index++) {
              expect(
                g.slotStart(index),
                closeTo(g.slotStart(index - 1) + g.slotWidth(index - 1), 0.001),
              );
            }
            final lastSlotEnd = g.slotStart(count - 1) + g.slotWidth(count - 1);
            expect(
              lastSlotEnd,
              closeTo(width - GlassMorphGeometry.edgeInset, 0.001),
            );
          }
        });

        test('the split card sits in the gap between the two pills', () {
          final g = geometry(1, itemCount: count);
          final leadingEnd = GlassMorphGeometry.edgeInset + g.leadingPillWidth;
          final trailingStart =
              width - GlassMorphGeometry.edgeInset - g.trailingPillWidth;
          // The card rect carries the edge inset on both sides; its visible
          // glass starts one gap after the leading pill and ends one gap
          // before the trailing pill.
          expect(
            g.playerStart + GlassMorphGeometry.edgeInset,
            closeTo(leadingEnd + GlassMorphGeometry.gap, 0.001),
          );
          expect(
            g.playerStart + g.playerWidth - GlassMorphGeometry.edgeInset,
            closeTo(trailingStart - GlassMorphGeometry.gap, 0.001),
          );
        });

        test('the card rect stays inside the bar at every progress', () {
          for (final progress in [0.0, 0.2, 0.5, 0.8, 1.0]) {
            final g = geometry(progress, itemCount: count);
            expect(g.playerStart, greaterThanOrEqualTo(0));
            expect(g.playerStart + g.playerWidth, lessThanOrEqualTo(width));
            expect(g.playerWidth, greaterThan(0));
          }
        });
      });
    }

    test('an odd count gives the trailing pill the extra tab', () {
      final g = geometry(0.5, itemCount: 5);
      expect(g.leadingCount, 2);
      expect(g.trailingCount, 3);
      expect(g.trailingPillWidth, greaterThan(g.leadingPillWidth));
    });

    test('rejects counts outside 2..6', () {
      expect(() => geometry(0, itemCount: 1), throwsAssertionError);
      expect(() => geometry(0, itemCount: 7), throwsAssertionError);
    });
  });

  test('height and width stay finite mid-morph', () {
    final mid = geometry(0.5);
    expect(mid.totalHeight, greaterThan(mid.splitPillHeight));
    expect(mid.playerWidth, greaterThan(0));
    expect(mid.playerWidth, lessThan(width));
  });
}
