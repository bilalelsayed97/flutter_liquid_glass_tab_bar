import 'package:flutter/widgets.dart';

import '../controller/tab_controller.dart';

/// Forwards the active tab's scroll frames to a [LiquidGlassTabController],
/// which decides whether the bar docks or splits.
///
/// Only depth-zero vertical scroll views drive the bar: nested horizontal
/// carousels and sheets must not collapse it.
class LiquidGlassTabScrollReporter extends StatelessWidget {
  /// Receives the scroll frames.
  final LiquidGlassTabController controller;

  /// The tab content.
  final Widget child;

  /// Creates the reporter.
  const LiquidGlassTabScrollReporter({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          if (notification.metrics.axis != Axis.vertical) return false;
          controller.reportScroll(
            offset: notification.metrics.pixels,
            delta: notification.scrollDelta ?? 0,
          );
          return false;
        },
        child: child,
      );
}
