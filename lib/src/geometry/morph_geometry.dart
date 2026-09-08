import 'dart:math' as math;
import 'dart:ui' show TextDirection, lerpDouble;

import '../theme/glass_spec.dart';
import 'tab_group.dart';

/// All arithmetic behind the bar's dock ↔ split morph.
///
/// The bar is three boxes stacked over the page — a leading tab pill, the
/// card, and a trailing tab pill — and this class says where each one sits
/// and how wide it is for a given [progress] (`0` docked, `1` split). The
/// widget only positions what it is told, and the motion can be unit-tested
/// without pumping a frame.
///
/// Docked, the two pills sit flush under a full-width card and read as one
/// continuous bar; split, they shrink to the first and last tab at either
/// edge and the card takes the space between them — every other tab folds
/// away. The first `itemCount ~/ 2` tabs form the leading group and the rest
/// the trailing group, so an odd count gives the trailing pill one more tab
/// and the two pills differ in width until the split completes.
///
/// Coordinates are the *rect* the card is laid out in, not its visible box:
/// the card carries [edgeInset] of padding on each side and
/// [cardBottomPadding] below, so its rect is inflated by that much to keep
/// its glass aligned with the pills.
class GlassMorphGeometry {
  /// Full width available to the bar.
  final double width;

  /// Morph progress the bar asked for: `0` docked, `1` split. Read [progress]
  /// instead — it also accounts for there being no card to move.
  final double requestedProgress;

  /// Measured height of the card's rect; `0` when no card shows.
  final double playerHeight;

  /// Height of a tab's label plus the gap above it, from `GlassPillMetrics`.
  /// The pill's height is derived from this rather than measured, so the
  /// morph never feeds its own output back in as input.
  final double labelBlockHeight;

  /// Whether labels fit at the active text scale.
  final bool showsLabels;

  /// Number of tabs in the bar.
  final int itemCount;

  /// Fewest tabs the bar lays out.
  static const int minItemCount = 2;

  /// Most tabs the bar lays out.
  static const int maxItemCount = 6;

  /// Distance from the screen edge to the bar's glass, matching the padding
  /// the card carries on each side.
  static const double edgeInset = 16;

  /// Horizontal gap between the card and a pill in the split layout.
  static const double gap = 8;

  /// Padding the card carries below its own glass. Part of the measured rect
  /// but not of the visible card, so every vertical placement subtracts it.
  static const double cardBottomPadding = 8;

  /// The lens owns the optical inset, so the row adds no second end margin.
  static const double pillPadding = 0;

  /// Padding a tab item carries above and below its content. Must stay equal
  /// to what `GlassItem` applies — the pill's height is derived from it.
  static const double itemVerticalPadding = 8;

  /// Width of one tab item once the pill has collapsed to icons only.
  static const double compactItemWidth = 48;

  /// Size of a tab glyph.
  static const double iconSize = 24;

  /// Minimum tappable height of a tab.
  static const double minTouchTarget = 48;

  /// Typical height of a compact card, used by [estimatedDockedHeight].
  static const double estimatedCardHeight = 56;

  /// Docked-height estimate for insetting page content before the first
  /// measured frame.
  static const double estimatedDockedHeight =
      estimatedCardHeight + GlassSpec.dockedHeight;

  /// Creates the geometry for one frame.
  const GlassMorphGeometry({
    required this.width,
    required double progress,
    required this.playerHeight,
    required this.labelBlockHeight,
    required this.showsLabels,
    required this.itemCount,
  }) : assert(
         itemCount >= minItemCount && itemCount <= maxItemCount,
         'LiquidGlassTabBar lays out $minItemCount to $maxItemCount tabs',
       ),
       requestedProgress = progress;

  /// The morph progress actually in effect. With no card to hand the centre
  /// to, splitting would leave a hole between two pills, so the bar stays
  /// docked. Clamped to `0..1`: everything below is only defined there.
  double get progress =>
      playerHeight <= 0 ? 0 : requestedProgress.clamp(0.0, 1.0);

  double get _labelBlock => showsLabels ? labelBlockHeight : 0;

  /// Height of a pill showing glyphs *and* labels.
  double get dockedPillHeight => math.max(
    GlassSpec.dockedHeight,
    2 * itemVerticalPadding + iconSize + _labelBlock,
  );

  /// Height of an icon-only pill.
  double get splitPillHeight =>
      math.max(minTouchTarget, 2 * itemVerticalPadding + iconSize);

  /// Height of a tab pill at the current [progress]. Derived, never measured.
  double get pillHeight => _lerp(dockedPillHeight, splitPillHeight);

  /// How much of the label's slot is still open — the `heightFactor` an item
  /// collapses its label with.
  double get labelVisibility => showsLabels ? 1 - progress : 0;

  /// Width of a tab that stays visible when the bar splits.
  double get itemWidth => _lerp(_dockedItemWidth, compactItemWidth);

  /// Width of a tab that folds away when the bar splits.
  double get collapsingItemWidth => _lerp(_dockedItemWidth, 0);

  /// How visible a folding tab's glyph is on the shared morph timeline.
  double get collapsingOpacity => 1 - progress;

  /// Total height the bar occupies at the current [progress].
  double get totalHeight => _lerp(_dockedHeight, _splitRowHeight);

  /// Distance from the bar's bottom edge to the card's rect.
  double get playerBottom => _lerp(
    dockedPillHeight,
    (_splitRowHeight - _visiblePlayerHeight) / 2 - cardBottomPadding,
  );

  /// Distance from the bar's bottom edge to the pills.
  double get pillBottom => _lerp(0, (_splitRowHeight - splitPillHeight) / 2);

  /// Distance from the bar's start edge to the card's rect.
  double get playerStart => _lerp(0, leadingPillWidth + gap);

  /// Distance from the bar's end edge to the card's rect.
  double get playerEnd => _lerp(0, trailingPillWidth + gap);

  /// Width of the card's rect at the current [progress].
  double get playerWidth => math.max(width - playerStart - playerEnd, 0);

  /// How visible labels are on the same timeline as width and glass.
  double get labelOpacity => showsLabels ? 1 - progress : 0;

  // ── Groups and slots ────────────────────────────────────────────────────

  /// Number of tabs in the leading pill.
  int get leadingCount => itemCount ~/ 2;

  /// Number of tabs in the trailing pill.
  int get trailingCount => itemCount - leadingCount;

  /// The pill tab [index] belongs to.
  GlassTabGroup groupOf(int index) =>
      index < leadingCount ? GlassTabGroup.leading : GlassTabGroup.trailing;

  /// Whether tab [index] stays visible when the bar splits — only the first
  /// and last tabs do.
  bool persistsWhenCollapsed(int index) => index == 0 || index == itemCount - 1;

  /// Width of the slot tab [index] occupies right now.
  double slotWidth(int index) =>
      persistsWhenCollapsed(index) ? itemWidth : collapsingItemWidth;

  /// Width of [group]'s pill at the current [progress]. Docked, the two pills
  /// add up to exactly the space between the insets.
  double pillWidthOf(GlassTabGroup group) {
    final start = group == GlassTabGroup.leading ? 0 : leadingCount;
    final end = group == GlassTabGroup.leading ? leadingCount : itemCount;
    var total = 2 * pillPadding;
    for (var index = start; index < end; index++) {
      total += slotWidth(index);
    }
    return total;
  }

  /// Width of the leading pill.
  double get leadingPillWidth => pillWidthOf(GlassTabGroup.leading);

  /// Width of the trailing pill.
  double get trailingPillWidth => pillWidthOf(GlassTabGroup.trailing);

  /// Offset of tab [index]'s slot from the bar's start edge.
  double slotStart(int index) {
    final isLeading = groupOf(index) == GlassTabGroup.leading;
    final pillStart = isLeading
        ? edgeInset
        : width - edgeInset - trailingPillWidth;
    var start = pillStart + pillPadding;
    for (var i = isLeading ? 0 : leadingCount; i < index; i++) {
      start += slotWidth(i);
    }
    return start;
  }

  /// Centre of tab [index]'s live slot, measured from the logical start edge.
  double slotCenter(int index) => slotStart(index) + slotWidth(index) / 2;

  /// Whether tab [index] is big enough to be picked by a tap or a drag.
  bool isSelectable(int index) => slotWidth(index) >= compactItemWidth / 2;

  /// The selectable tab whose slot centre is nearest [coordinate].
  int indexAt(double coordinate) {
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < itemCount; index++) {
      if (!isSelectable(index)) continue;
      final distance = (slotCenter(index) - coordinate).abs();
      if (distance >= nearestDistance) continue;
      nearest = index;
      nearestDistance = distance;
    }
    return nearest;
  }

  /// Converts a bar-local x into a start-edge coordinate, so the same slot
  /// arithmetic works in both text directions.
  double startCoordinate(double localX, TextDirection textDirection) =>
      textDirection == TextDirection.rtl ? width - localX : localX;

  /// Clamps a highlight offset so a dragged highlight can't leave the tabs.
  double clampSlotStart(double start) =>
      start.clamp(slotStart(0), slotStart(itemCount - 1));

  double get _contentWidth => math.max(width - 2 * edgeInset, 0);

  double get _dockedItemWidth => (_contentWidth - 4 * pillPadding) / itemCount;

  double get _visiblePlayerHeight =>
      math.max(playerHeight - cardBottomPadding, 0);

  double get _dockedHeight => playerHeight + dockedPillHeight;

  double get _splitRowHeight => math.max(_visiblePlayerHeight, splitPillHeight);

  double _lerp(double from, double to) => lerpDouble(from, to, progress)!;
}
