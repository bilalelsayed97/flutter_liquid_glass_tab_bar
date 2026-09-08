import 'package:flutter/widgets.dart';

import '../geometry/item_ui_model.dart';
import '../geometry/morph_geometry.dart';
import '../geometry/tab_group.dart';
import 'item.dart';
import 'item_params.dart';
import 'pill_params.dart';

/// One group of the bar's tabs. The glass underneath and the lens are both
/// painted by the bar across the full strip, so this widget is transparent
/// and holds only its items.
///
/// The pill behaves like a slider: a press arms the lens, movement past
/// touch slop carries it under the finger, and release selects through the
/// shared spring. Items therefore carry no pointer gestures of their own.
class GlassPill extends StatelessWidget {
  /// Everything the pill renders.
  final GlassPillParams params;

  /// Creates the pill.
  const GlassPill({super.key, required this.params});

  double _widthOf(GlassItemUiModel item) => item.persistsWhenCollapsed
      ? params.itemWidth
      : params.collapsingItemWidth;

  double _opacityOf(GlassItemUiModel item) =>
      item.persistsWhenCollapsed ? 1 : params.collapsingOpacity;

  @override
  Widget build(BuildContext context) {
    final isLeading = params.group == GlassTabGroup.leading;
    return PositionedDirectional(
      start: isLeading ? GlassMorphGeometry.edgeInset : null,
      end: isLeading ? null : GlassMorphGeometry.edgeInset,
      bottom: params.bottom,
      width: params.pillWidth,
      height: params.height,
      child: Listener(
        // Opaque so the whole pill answers a touch, not just the glyphs. Raw
        // pointers rather than gestures because the lens needs absolute
        // positions and timestamps while a drag is active.
        behavior: HitTestBehavior.opaque,
        onPointerDown: params.onPointerDown,
        onPointerMove: params.onPointerMove,
        onPointerUp: params.onPointerUp,
        onPointerCancel: (_) => params.onPointerCancel?.call(),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: GlassMorphGeometry.pillPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in params.items)
                GlassItem(
                  key: ValueKey(item.index),
                  params: GlassItemParams(
                    item: item,
                    onTap: () => params.onSelect(item.index),
                    width: _widthOf(item),
                    labelVisibility: params.labelVisibility,
                    labelOpacity: params.labelOpacity,
                    opacity: _opacityOf(item),
                    activeColor: params.activeColor,
                    inactiveColor: params.inactiveColor,
                    labelStyle: params.labelStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
