import 'package:flutter/widgets.dart';

import '../controller/tab_controller.dart';
import 'tab_scope.dart';

/// Registers a tab's primary [ScrollController] with the
/// [LiquidGlassTabController] so re-tapping the tab scrolls it to the top.
///
/// Place it inside a tab (below a [LiquidGlassTabScope]); it reads the tab's
/// index from the scope, registers on mount and unregisters on dispose. The
/// scroll controller stays yours to dispose.
class LiquidGlassTabScrollTarget extends StatefulWidget {
  /// The shell's controller.
  final LiquidGlassTabController tabController;

  /// The tab's primary scroll controller.
  final ScrollController scrollController;

  /// The tab content.
  final Widget child;

  /// Creates the target.
  const LiquidGlassTabScrollTarget({
    super.key,
    required this.tabController,
    required this.scrollController,
    required this.child,
  });

  @override
  State<LiquidGlassTabScrollTarget> createState() =>
      _LiquidGlassTabScrollTargetState();
}

class _LiquidGlassTabScrollTargetState
    extends State<LiquidGlassTabScrollTarget> {
  int? _index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register(LiquidGlassTabScope.maybeOf(context)?.index);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabScrollTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController ||
        oldWidget.scrollController != widget.scrollController) {
      _unregister(oldWidget);
      _index = null;
      _register(LiquidGlassTabScope.maybeOf(context)?.index);
    }
  }

  void _register(int? index) {
    if (index == null || index == _index) return;
    _unregister(widget);
    _index = index;
    widget.tabController.registerScrollController(
      index,
      widget.scrollController,
    );
  }

  void _unregister(LiquidGlassTabScrollTarget target) {
    final index = _index;
    if (index == null) return;
    target.tabController.unregisterScrollController(
      index,
      target.scrollController,
    );
  }

  @override
  void dispose() {
    _unregister(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
