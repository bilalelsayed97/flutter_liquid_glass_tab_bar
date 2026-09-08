import 'package:flutter/widgets.dart';

import 'tab_scope.dart';

/// Keeps every visited tab alive behind the bar.
///
/// An [IndexedStack] rather than a rebuilt child so scroll offsets, search
/// text and list positions survive a tab switch. Tabs are built lazily: a
/// tab that has never been opened costs nothing. Hidden tabs have their
/// tickers muted so an offscreen tab costs no frames, and each tab is
/// wrapped in a [LiquidGlassTabScope].
class LiquidGlassTabHost extends StatefulWidget {
  /// Index of the visible tab.
  final int selectedIndex;

  /// One builder per tab, in bar order.
  final List<WidgetBuilder> tabBuilders;

  /// Creates the host.
  const LiquidGlassTabHost({
    super.key,
    required this.selectedIndex,
    required this.tabBuilders,
  });

  @override
  State<LiquidGlassTabHost> createState() => _LiquidGlassTabHostState();
}

class _LiquidGlassTabHostState extends State<LiquidGlassTabHost> {
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.selectedIndex);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.selectedIndex,
    children: [
      for (var index = 0; index < widget.tabBuilders.length; index++)
        if (_visited.contains(index))
          TickerMode(
            enabled: index == widget.selectedIndex,
            child: LiquidGlassTabScope(
              index: index,
              child: Builder(builder: widget.tabBuilders[index]),
            ),
          )
        else
          const SizedBox.shrink(),
    ],
  );
}
