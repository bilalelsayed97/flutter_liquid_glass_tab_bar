import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';

/// A scrolling feed of colourful cards: scroll down to split the bar, scroll
/// up to dock it, re-tap the tab to scroll back to the top.
class DemoFeedPage extends StatefulWidget {
  final String title;
  final Color seed;
  final LiquidGlassTabController tabController;

  const DemoFeedPage({
    super.key,
    required this.title,
    required this.seed,
    required this.tabController,
  });

  @override
  State<DemoFeedPage> createState() => _DemoFeedPageState();
}

class _DemoFeedPageState extends State<DemoFeedPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LiquidGlassTabScrollTarget(
    tabController: widget.tabController,
    scrollController: _scroll,
    child: ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        LiquidGlassTabBar.estimatedDockedHeight +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      itemCount: 60,
      itemBuilder: (context, index) {
        final hue = (HSLColor.fromColor(widget.seed).hue + index * 23) % 360;
        final color = HSLColor.fromAHSL(1, hue, 0.7, 0.55).toColor();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.55)],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: Text(
              '${widget.title} ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    ),
  );
}
