import 'package:flutter/widgets.dart';

/// Marks a subtree as one of the shell's tabs, and says which tab it is.
///
/// Screens with two entry points — mounted as a tab *and* pushed as a route
/// of their own — can ask this to avoid duplicating chrome the shell already
/// provides. Asking the router (`canPop()`) answers a different question and
/// is not a rebuild dependency; this scope is both precise and inherited.
class LiquidGlassTabScope extends InheritedWidget {
  /// Index of the tab this subtree renders.
  final int index;

  /// Creates the scope.
  const LiquidGlassTabScope({
    super.key,
    required this.index,
    required super.child,
  });

  /// The enclosing scope, or `null` when this subtree is not a shell tab.
  static LiquidGlassTabScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidGlassTabScope>();

  /// Whether [context] is inside a shell tab rather than a pushed route.
  static bool isTab(BuildContext context) => maybeOf(context) != null;

  @override
  bool updateShouldNotify(LiquidGlassTabScope oldWidget) =>
      index != oldWidget.index;
}
