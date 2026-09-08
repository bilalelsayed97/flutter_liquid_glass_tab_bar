import 'package:flutter/widgets.dart';

import '../geometry/morph_geometry.dart';
import '../geometry/pill_metrics.dart';
import 'item_params.dart';

/// One tab: a glyph with a label that collapses away as the bar splits.
///
/// Purely visual for touch — the pill around it tracks the finger and
/// decides which tab a press lands on, so this widget carries no tap
/// handler. It does expose a semantics node with an activation action, so a
/// screen reader can still select the tab directly. Everything that can
/// shrink is clipped rather than removed, so the collapse stays continuous,
/// and the item keeps a 48pt minimum height at every progress value.
class GlassItem extends StatelessWidget {
  /// Everything the item renders.
  final GlassItemParams params;

  /// Creates the item.
  const GlassItem({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final item = params.item;
    final base = Color.lerp(
      params.inactiveColor,
      params.activeColor,
      item.selectionInfluence,
    )!;
    return ExcludeSemantics(
      excluding: !params.isInteractive,
      child: Semantics(
        button: true,
        selected: item.selected,
        label: item.item.resolvedSemanticLabel,
        onTap: params.onTap,
        // One node per tab: the glyph is decorative and the label repeats
        // what this node already announces.
        excludeSemantics: true,
        child: SizedBox(
          width: params.width,
          child: ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: GlassMorphGeometry.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: GlassMorphGeometry.itemVerticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: params.visualScale,
                      child: Icon(
                        item.item.iconFor(selected: item.selected),
                        size: GlassMorphGeometry.iconSize,
                        color: base.withValues(
                          alpha: base.a * params.iconAlpha,
                        ),
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        heightFactor: params.labelVisibility,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: GlassPillMetrics.labelGap,
                          ),
                          child: Text(
                            item.item.label,
                            style: params.labelStyle.copyWith(
                              color: base.withValues(
                                alpha: base.a * params.labelAlpha,
                              ),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
