import 'package:flutter/widgets.dart';

import '../controller/tab_controller.dart';

/// Rebuilds [builder] only when the controller's selected index changes.
///
/// A docked ↔ split flip must not rebuild an [IndexedStack] holding every
/// visited tab — that jank used to land on the first frame of the morph.
class GlassSelectedIndexBuilder extends StatefulWidget {
  /// The shell's controller.
  final LiquidGlassTabController controller;

  /// Builds for the current selected index.
  final Widget Function(BuildContext context, int selectedIndex) builder;

  /// Creates the builder.
  const GlassSelectedIndexBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<GlassSelectedIndexBuilder> createState() =>
      _GlassSelectedIndexBuilderState();
}

class _GlassSelectedIndexBuilderState extends State<GlassSelectedIndexBuilder> {
  late int _selectedIndex = widget.controller.selectedIndex;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant GlassSelectedIndexBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _selectedIndex = widget.controller.selectedIndex;
    }
  }

  void _onChanged() {
    final next = widget.controller.selectedIndex;
    if (next == _selectedIndex) return;
    setState(() => _selectedIndex = next);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _selectedIndex);
}
