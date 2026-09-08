/// A liquid-glass bottom tab bar: refractive Impeller shader with a
/// non-Impeller fallback, drag-to-select lens, scroll-driven dock/split morph
/// and a card slot.
library;

export 'src/controller/tab_controller.dart' show LiquidGlassTabController;
export 'src/model/collapse_policy.dart' show LiquidGlassCollapsePolicy;
export 'src/model/scroll_gesture.dart' show LiquidGlassScrollGesture;
export 'src/model/tab_item.dart' show LiquidGlassTabItem;
export 'src/model/tab_layout.dart' show LiquidGlassTabLayout;
export 'src/shader/repaint_scope.dart' show LiquidGlassRepaintScope;
export 'src/shader/shader_precache.dart'
    show kLiquidGlassShaderAssetKey, precacheLiquidGlassShader;
export 'src/shader/shader_support.dart' show LiquidGlassShaderSupport;
export 'src/theme/tab_bar_theme.dart' show LiquidGlassTabBarTheme;
export 'src/widgets/hidden_in_tab.dart' show HiddenInTab;
export 'src/widgets/scroll_reporter.dart' show LiquidGlassTabScrollReporter;
export 'src/widgets/scroll_target.dart' show LiquidGlassTabScrollTarget;
export 'src/widgets/tab_bar.dart' show LiquidGlassTabBar;
export 'src/widgets/tab_host.dart' show LiquidGlassTabHost;
export 'src/widgets/tab_scaffold.dart' show LiquidGlassTabScaffold;
export 'src/widgets/tab_scope.dart' show LiquidGlassTabScope;
