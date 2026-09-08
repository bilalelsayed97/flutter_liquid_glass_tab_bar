// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/collapse_policy.dart';
import '../model/scroll_gesture.dart';
import '../model/tab_layout.dart';
import '../theme/glass_motion.dart';
import 'tab_scroll_registry.dart';

/// Owns which tab is selected and whether the bar is docked or split.
///
/// Feed it scroll frames with [reportScroll] (a [LiquidGlassTabScrollReporter]
/// does this for you) and it applies the [LiquidGlassCollapsePolicy]; it
/// notifies only when the layout or selection actually changes, so scrolling
/// never rebuilds the shell on every frame.
class LiquidGlassTabController extends ChangeNotifier {
  final LiquidGlassCollapsePolicy _collapsePolicy;
  final ValueListenable<bool>? _hasCard;
  final GlassTabScrollRegistry _scrollRegistry;

  /// Called with the new index on every real tab switch. Re-tapping the
  /// current tab is a scroll-to-top gesture, not navigation, and does not
  /// fire it — handy for analytics.
  final ValueChanged<int>? onTabSelected;

  int _selectedIndex;
  LiquidGlassTabLayout _layout = LiquidGlassTabLayout.docked;

  /// Accumulated scroll, folded frame by frame and handed to the policy.
  /// Transient input rather than state: nothing renders from it.
  LiquidGlassScrollGesture _gesture = const LiquidGlassScrollGesture();

  /// Creates a controller starting on [initialIndex].
  ///
  /// [hasCard] tells the bar whether there is a card to centre; when it flips
  /// to `false` the bar docks. Leave it `null` when the card is always
  /// present or always absent (an absent card never splits anyway).
  LiquidGlassTabController({
    int initialIndex = 0,
    LiquidGlassCollapsePolicy collapsePolicy =
        const LiquidGlassCollapsePolicy(),
    ValueListenable<bool>? hasCard,
    this.onTabSelected,
    Duration scrollToTopDuration = GlassMotion.scrollToTop,
    Curve scrollToTopCurve = GlassMotion.emphasized,
  }) : _selectedIndex = initialIndex,
       _collapsePolicy = collapsePolicy,
       _hasCard = hasCard,
       _scrollRegistry = GlassTabScrollRegistry(
         duration: scrollToTopDuration,
         curve: scrollToTopCurve,
       ) {
    _hasCard?.addListener(_onHasCardChanged);
  }

  /// Index of the selected tab.
  int get selectedIndex => _selectedIndex;

  /// The layout the bar should be in.
  LiquidGlassTabLayout get layout => _layout;

  bool get _cardPresent => _hasCard?.value ?? true;

  /// Switches to [index]; re-selecting the current tab scrolls it to the top
  /// instead (the iOS tab-bar convention). Switching also re-docks the bar so
  /// a freshly shown tab always starts from its full-width layout.
  void selectIndex(int index) {
    if (_selectedIndex == index) {
      _scrollRegistry.scrollToTop(index);
      return;
    }
    // The new tab has its own scroll position, so travel banked against the
    // old one must not carry over and immediately re-split the fresh bar.
    _gesture = _gesture.reset();
    _selectedIndex = index;
    _layout = LiquidGlassTabLayout.docked;
    notifyListeners();
    onTabSelected?.call(index);
  }

  /// Feeds one scroll frame from the active tab into the collapse policy.
  void reportScroll({required double offset, required double delta}) {
    _gesture = _gesture.extend(offset: offset, delta: delta);
    final layout = _collapsePolicy.resolve(
      gesture: _gesture,
      current: _layout,
      hasCard: _cardPresent,
    );
    if (layout == _layout) return;
    // The travel that earned this flip is spent. Without the reset it would
    // keep clearing the threshold on every following frame of the same drag.
    _gesture = _gesture.reset();
    _layout = layout;
    notifyListeners();
  }

  /// Returns the bar to its docked layout.
  void dock() {
    if (_layout == LiquidGlassTabLayout.docked) return;
    _gesture = _gesture.reset();
    _layout = LiquidGlassTabLayout.docked;
    notifyListeners();
  }

  /// Registers the primary scroll view of tab [index] for scroll-to-top.
  /// [LiquidGlassTabScrollTarget] does this from the widget tree.
  void registerScrollController(int index, ScrollController controller) =>
      _scrollRegistry.register(index, controller);

  /// Undoes [registerScrollController]; a no-op if a newer controller has
  /// since taken the slot.
  void unregisterScrollController(int index, ScrollController controller) =>
      _scrollRegistry.unregister(index, controller);

  /// Animates tab [index]'s registered scroll view to the top.
  void scrollToTop(int index) => _scrollRegistry.scrollToTop(index);

  void _onHasCardChanged() {
    if (!_cardPresent) dock();
  }

  @override
  void dispose() {
    _hasCard?.removeListener(_onHasCardChanged);
    super.dispose();
  }
}
