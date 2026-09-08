import 'package:flutter/widgets.dart';

import '../controller/tab_controller.dart';
import '../model/tab_item.dart';
import '../theme/tab_bar_theme.dart';
import 'scroll_reporter.dart';
import 'selected_index_builder.dart';
import 'tab_bar.dart';
import 'tab_host.dart';

/// The app shell: the tabs with the floating glass bar stacked over them.
///
/// Put it in `Scaffold.body`. The bar is stacked over the content rather
/// than placed in `bottomNavigationBar` because its glass needs page content
/// behind it to refract, and its docked/split layouts change height.
class LiquidGlassTabScaffold extends StatelessWidget {
  /// Owns selection and layout.
  final LiquidGlassTabController controller;

  /// The tabs, in bar order. Between two and six.
  final List<LiquidGlassTabItem> items;

  /// One builder per tab, matching [items].
  final List<WidgetBuilder> tabBuilders;

  /// See [LiquidGlassTabBar.card].
  final Widget? card;

  /// See [LiquidGlassTabBar.theme].
  final LiquidGlassTabBarTheme? theme;

  /// See [LiquidGlassTabBar.reduceMotion].
  final bool? reduceMotion;

  /// See [LiquidGlassTabBar.enableHaptics].
  final bool enableHaptics;

  /// See [LiquidGlassTabBar.maxLabelTextScale].
  final double maxLabelTextScale;

  /// Creates the shell.
  const LiquidGlassTabScaffold({
    super.key,
    required this.controller,
    required this.items,
    required this.tabBuilders,
    this.card,
    this.theme,
    this.reduceMotion,
    this.enableHaptics = true,
    this.maxLabelTextScale = 1.5,
  }) : assert(
         items.length == tabBuilders.length,
         'items and tabBuilders must have the same length',
       );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        // The bar repaints on every frame of its morph. Without this
        // boundary that dirties the shared layer and drags the whole tab
        // host into each of those repaints.
        child: RepaintBoundary(
          child: LiquidGlassTabScrollReporter(
            controller: controller,
            child: GlassSelectedIndexBuilder(
              controller: controller,
              builder: (context, selectedIndex) => LiquidGlassTabHost(
                selectedIndex: selectedIndex,
                tabBuilders: tabBuilders,
              ),
            ),
          ),
        ),
      ),
      PositionedDirectional(
        start: 0,
        end: 0,
        bottom: 0,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => LiquidGlassTabBar(
            items: items,
            selectedIndex: controller.selectedIndex,
            layout: controller.layout,
            onSelect: controller.selectIndex,
            card: card,
            theme: theme,
            reduceMotion: reduceMotion,
            enableHaptics: enableHaptics,
            maxLabelTextScale: maxLabelTextScale,
          ),
        ),
      ),
    ],
  );
}
