import 'package:flutter/widgets.dart';

import '../geometry/active_surface_resolver.dart';
import '../geometry/highlight_placement.dart';
import '../geometry/item_ui_model.dart';
import '../geometry/items_builder.dart';
import '../geometry/lens_driver.dart';
import '../geometry/morph_driver.dart';
import '../geometry/morph_geometry.dart';
import '../geometry/pill_metrics.dart';
import '../geometry/split_bar_shape.dart';
import '../geometry/tab_group.dart';
import '../geometry/widget_height_reader.dart';
import '../model/tab_item.dart';
import '../model/tab_layout.dart';
import '../shader/repaint_scope.dart';
import '../shader/shader_support.dart';
import '../theme/tab_bar_theme.dart';
import 'glass_surface.dart';
import 'glass_surface_params.dart';
import 'pill.dart';
import 'pill_params.dart';
import 'selection_highlight.dart';

/// A floating liquid-glass tab bar, drawn entirely in Flutter so iOS and
/// Android share one design and one animation.
///
/// It hosts three boxes — a leading tab pill, an optional [card], and a
/// trailing tab pill — and animates them between the docked layout (card
/// above one continuous pill) and the split layout (card centred between two
/// icon-only pills). The card is a single widget instance that travels, so
/// its state survives the morph. Selection is a lens that follows the finger
/// along the bar and commits on release.
///
/// Stack it over the page content rather than putting it in
/// `Scaffold.bottomNavigationBar`: its glass needs content behind it to
/// refract, and its height changes between layouts. [LiquidGlassTabScaffold]
/// does this wiring for you.
class LiquidGlassTabBar extends StatefulWidget {
  /// The tabs, in bar order. Between two and six.
  final List<LiquidGlassTabItem> items;

  /// Index of the selected tab.
  final int selectedIndex;

  /// The layout to settle into.
  final LiquidGlassTabLayout layout;

  /// Called with the index the user selected.
  final ValueChanged<int> onSelect;

  /// Widget positioned above the pills when docked and between them when
  /// split — a mini player, a banner. Hand in the bare widget; the bar adds
  /// the padding that lines its edges up with the pills.
  final Widget? card;

  /// Colours and label style. Defaults to [LiquidGlassTabBarTheme.of].
  final LiquidGlassTabBarTheme? theme;

  /// Removes spring overshoot and velocity response. Defaults to the
  /// platform's reduce-motion setting.
  final bool? reduceMotion;

  /// Whether a drag ticks the haptic engine as the lens crosses tabs.
  final bool enableHaptics;

  /// Text scale above which labels are dropped instead of ellipsized.
  final double maxLabelTextScale;

  /// Whether the bar insets itself above the bottom safe area.
  final bool useSafeArea;

  /// Docked-height estimate for insetting page content before the first
  /// measured frame, assuming a compact card.
  static const double estimatedDockedHeight =
      GlassMorphGeometry.estimatedDockedHeight;

  /// Distance from the screen edge to the bar's glass.
  static const double edgeInset = GlassMorphGeometry.edgeInset;

  /// Creates the bar.
  const LiquidGlassTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.layout = LiquidGlassTabLayout.docked,
    this.card,
    this.theme,
    this.reduceMotion,
    this.enableHaptics = true,
    this.maxLabelTextScale = 1.5,
    this.useSafeArea = true,
  }) : assert(
         items.length >= GlassMorphGeometry.minItemCount &&
             items.length <= GlassMorphGeometry.maxItemCount,
         'LiquidGlassTabBar lays out 2 to 6 tabs',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < items.length,
         'selectedIndex must index into items',
       );

  @override
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar>
    with TickerProviderStateMixin {
  static const GlassItemsBuilder _itemsBuilder = GlassItemsBuilder();
  static const GlassWidgetHeightReader _heightReader =
      GlassWidgetHeightReader();
  static const GlassPillMetrics _pillMetrics = GlassPillMetrics();
  static const GlassHighlightPlacement _placement = GlassHighlightPlacement();
  static const GlassActiveSurfaceResolver _surfaceResolver =
      GlassActiveSurfaceResolver();

  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  late final GlassMorphDriver _driver;
  late final GlassLensDriver _lensDriver;

  /// Merged once rather than per build — this is what the bar rebuilds on.
  late final Listenable _repaint;

  double _cardHeight = 0;
  bool _measureScheduled = false;

  /// Label metrics, recomputed only when the text scaler, locale or theme
  /// changes — never per frame.
  double _labelBlockHeight = 0;
  bool _showsLabels = true;

  bool get _isSplit => widget.layout == LiquidGlassTabLayout.split;

  LiquidGlassTabBarTheme _theme(BuildContext context) =>
      widget.theme ?? LiquidGlassTabBarTheme.of(context);

  @override
  void initState() {
    super.initState();
    _driver = GlassMorphDriver(vsync: this, split: _isSplit);
    _lensDriver = GlassLensDriver(
      vsync: this,
      committedIndex: widget.selectedIndex,
      enableHaptics: widget.enableHaptics,
    );
    _repaint = Listenable.merge([_driver.progress, _lensDriver]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lensDriver.reduceMotion =
        widget.reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    final scaler = MediaQuery.textScalerOf(context);
    _showsLabels = scaler.scale(1) <= widget.maxLabelTextScale;
    _labelBlockHeight = _pillMetrics.labelBlockHeight(
      // Merged the way `Text` merges it, or the ambient line height is
      // missed and every pill comes out a few points short.
      labelStyle: DefaultTextStyle.of(
        context,
      ).style.merge(_theme(context).labelStyle),
      textScaler: scaler,
      textDirection: Directionality.of(context),
      showsLabels: _showsLabels,
    );
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Guarded: re-issuing the motion on every unrelated rebuild restarts the
    // simulation, which is what used to leave the morph stranded.
    if (oldWidget.layout != widget.layout) _driver.settleTo(split: _isSplit);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      _lensDriver.reduceMotion =
          widget.reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    }
    _lensDriver.syncCommittedIndex(widget.selectedIndex);
  }

  @override
  void dispose() {
    _driver.dispose();
    _lensDriver.dispose();
    super.dispose();
  }

  /// Re-reads the card's height after the next frame. Latched, so a burst of
  /// size notifications collapses into one read.
  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measureNow();
    });
  }

  void _measureNow() {
    if (!mounted) return;
    final height = _heightReader.heightOf(_cardKey) ?? _cardHeight;
    if (!_heightReader.changed(_cardHeight, height)) return;
    setState(() => _cardHeight = height);
  }

  void _onPointerDown(PointerDownEvent event) {
    final coordinate = _coordinateOf(event.position);
    final geometry = _geometryForBar();
    if (coordinate == null || geometry == null) return;
    _lensDriver.begin(
      coordinate: coordinate,
      timeStamp: event.timeStamp,
      geometry: geometry,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    final coordinate = _coordinateOf(event.position);
    final geometry = _geometryForBar();
    if (geometry == null || coordinate == null) return;
    _lensDriver.update(
      coordinate: coordinate,
      timeStamp: event.timeStamp,
      geometry: geometry,
    );
  }

  /// Commits once on release; the lens spring keeps settling independently.
  void _onPointerUp(PointerUpEvent event) {
    final coordinate = _coordinateOf(event.position);
    final geometry = _geometryForBar();
    if (geometry == null || coordinate == null) {
      _lensDriver.cancel();
      return;
    }
    _lensDriver.update(
      coordinate: coordinate,
      timeStamp: event.timeStamp,
      geometry: geometry,
    );
    widget.onSelect(
      _lensDriver.end(coordinate: coordinate, geometry: geometry),
    );
  }

  void _onPointerCancel() => _lensDriver.cancel();

  /// A touch's global position as an offset from the bar's start edge, or
  /// `null` before the bar has been laid out.
  double? _coordinateOf(Offset globalPosition) {
    final box = _barKey.currentContext?.findRenderObject();
    final geometry = _geometryForBar();
    if (geometry == null || box is! RenderBox) return null;
    return geometry.startCoordinate(
      box.globalToLocal(globalPosition).dx,
      Directionality.of(context),
    );
  }

  /// Rebuilt on demand from the bar's own box rather than cached from the
  /// last build, so a drag always resolves against the frame the finger is
  /// actually on.
  GlassMorphGeometry? _geometryForBar() {
    final box = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return _geometryFor(box.size.width);
  }

  GlassMorphGeometry _geometryFor(double width) => GlassMorphGeometry(
    width: width,
    progress: _driver.progress.value,
    playerHeight: _cardHeight,
    labelBlockHeight: _labelBlockHeight,
    showsLabels: _showsLabels,
    itemCount: widget.items.length,
  );

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final card = widget.card;
    final content = LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _repaint,
        // The card is not rebuilt during the morph. Its boundary still lets a
        // backdrop-sampling card repaint from the scope below, without
        // dirtying the tab host behind the whole bar.
        child: LiquidGlassRepaintScope(
          repaint: _repaint,
          child: RepaintBoundary(
            child: NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _scheduleMeasure();
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: KeyedSubtree(
                  key: _cardKey,
                  child: card == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: GlassMorphGeometry.edgeInset,
                            end: GlassMorphGeometry.edgeInset,
                            bottom: GlassMorphGeometry.cardBottomPadding,
                          ),
                          child: card,
                        ),
                ),
              ),
            ),
          ),
        ),
        builder: (context, card) => _buildBar(
          context,
          theme: theme,
          width: constraints.maxWidth,
          card: card!,
        ),
      ),
    );
    if (!widget.useSafeArea) return content;
    return SafeArea(top: false, bottom: true, child: content);
  }

  Widget _buildBar(
    BuildContext context, {
    required LiquidGlassTabBarTheme theme,
    required double width,
    required Widget card,
  }) {
    final geometry = _geometryFor(width);
    final lens = _lensDriver.state;
    final highlight = _placement.placementOf(geometry: geometry, lens: lens);
    final restingPillTint = _restingPillTint(theme);
    final supportsShader = LiquidGlassShaderSupport.isAvailable;
    final activeSurface = _surfaceResolver.resolve(
      geometry: geometry,
      surfaceAmount: _lensDriver.surfaceAmount,
      supportsShader: supportsShader,
    );
    final restingGlassShape = GlassSplitBarShape(
      leadingWidth: geometry.leadingPillWidth,
      trailingWidth: geometry.trailingPillWidth,
      inset: GlassMorphGeometry.edgeInset,
    );
    return SizedBox(
      key: _barKey,
      height: activeSurface.totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassSurface(
            params: GlassSurfaceParams(
              shape: restingGlassShape,
              height: activeSurface.materialHeight,
              restingHeight: geometry.pillHeight,
              bottom: activeSurface.materialBottom,
              leadingWidth: geometry.leadingPillWidth,
              trailingWidth: geometry.trailingPillWidth,
              outerInset: GlassMorphGeometry.edgeInset,
              morphProgress: geometry.progress,
              surfaceAmount: _lensDriver.surfaceAmount,
              highlight: highlight,
              tint: theme.tint,
              tintOpacity: theme.tintOpacity,
              selectedPillTint: restingPillTint,
              attenuation: theme.attenuationColor,
              specular: theme.specularColor,
            ),
          ),
          if (!supportsShader)
            GlassSelectionHighlight(
              params: highlight,
              tint: restingPillTint,
              attenuation: theme.attenuationColor,
              specular: theme.specularColor,
            ),
          PositionedDirectional(
            start: geometry.playerStart,
            width: geometry.playerWidth,
            bottom: geometry.playerBottom,
            child: card,
          ),
          for (final group in GlassTabGroup.values)
            GlassPill(
              params: _pillParams(
                theme: theme,
                items: _itemsBuilder.itemsOf(
                  items: widget.items,
                  selectedIndex: widget.selectedIndex,
                  group: group,
                  geometry: geometry,
                  visualPosition: lens.position,
                ),
                group: group,
                geometry: geometry,
              ),
            ),
        ],
      ),
    );
  }

  GlassPillParams _pillParams({
    required LiquidGlassTabBarTheme theme,
    required List<GlassItemUiModel> items,
    required GlassTabGroup group,
    required GlassMorphGeometry geometry,
  }) => GlassPillParams(
    items: items,
    onSelect: widget.onSelect,
    onPointerDown: _onPointerDown,
    onPointerMove: _onPointerMove,
    onPointerUp: _onPointerUp,
    onPointerCancel: _onPointerCancel,
    group: group,
    pillWidth: geometry.pillWidthOf(group),
    bottom: geometry.pillBottom,
    height: geometry.pillHeight,
    itemWidth: geometry.itemWidth,
    collapsingItemWidth: geometry.collapsingItemWidth,
    collapsingOpacity: geometry.collapsingOpacity,
    labelVisibility: geometry.labelVisibility,
    labelOpacity: geometry.labelOpacity,
    activeColor: theme.activeColor,
    inactiveColor: theme.inactiveColor,
    labelStyle: theme.labelStyle,
  );

  Color _restingPillTint(LiquidGlassTabBarTheme theme) {
    final tint = theme.indicatorColor;
    return tint.withValues(alpha: _lensDriver.isAtRest ? tint.a : 0);
  }
}
