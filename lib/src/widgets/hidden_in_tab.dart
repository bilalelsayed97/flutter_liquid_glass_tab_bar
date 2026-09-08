import 'package:flutter/widgets.dart';

import 'tab_scope.dart';

/// Renders [child] only when the screen around it was pushed as a route of
/// its own, and nothing when it is running as one of the shell's tabs — for
/// chrome the shell already provides, such as the card.
class HiddenInTab extends StatelessWidget {
  /// Shown only outside a shell tab.
  final Widget child;

  /// Creates the wrapper.
  const HiddenInTab({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      LiquidGlassTabScope.isTab(context) ? const SizedBox.shrink() : child;
}
