import '../model/tab_item.dart';
import 'item_ui_model.dart';
import 'lens_position_resolver.dart';
import 'morph_geometry.dart';
import 'tab_group.dart';

/// Turns the tab list and the selection into the bar's UI models, so the
/// widgets never filter tabs or resolve emphasis themselves.
class GlassItemsBuilder {
  static const GlassLensPositionResolver _lensPositionResolver =
      GlassLensPositionResolver();

  /// Creates the stateless builder.
  const GlassItemsBuilder();

  /// Only the tabs belonging to [group] — one half of the split layout.
  List<GlassItemUiModel> itemsOf({
    required List<LiquidGlassTabItem> items,
    required int selectedIndex,
    required GlassTabGroup group,
    required GlassMorphGeometry geometry,
    required double visualPosition,
  }) => [
    for (var index = 0; index < items.length; index++)
      if (geometry.groupOf(index) == group)
        GlassItemUiModel(
          index: index,
          item: items[index],
          selected: index == selectedIndex,
          persistsWhenCollapsed: geometry.persistsWhenCollapsed(index),
          selectionInfluence: _lensPositionResolver.influenceOf(
            position: visualPosition,
            index: index,
          ),
        ),
  ];
}
