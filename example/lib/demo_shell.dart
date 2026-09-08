import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';

import 'demo_card.dart';
import 'demo_feed_page.dart';
import 'demo_settings.dart';
import 'demo_settings_page.dart';

/// The tab shell: up to six tabs, the last one always being Settings.
class DemoShell extends StatefulWidget {
  final DemoSettings settings;

  const DemoShell({super.key, required this.settings});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  late final ValueNotifier<bool> _hasCard = ValueNotifier(
    widget.settings.showCard,
  );
  late final LiquidGlassTabController _controller = LiquidGlassTabController(
    hasCard: _hasCard,
    onTabSelected: (index) => debugPrint('selected tab $index'),
  );

  static const _all = [
    (icon: CupertinoIcons.house_fill, label: 'Home', seed: Color(0xFF4361EE)),
    (icon: CupertinoIcons.search, label: 'Search', seed: Color(0xFFEA3A43)),
    (
      icon: CupertinoIcons.music_note_list,
      label: 'Library',
      seed: Color(0xFF11A8A0),
    ),
    (icon: CupertinoIcons.heart_fill, label: 'Saved', seed: Color(0xFFF2B632)),
    (icon: CupertinoIcons.person_fill, label: 'Me', seed: Color(0xFF9B5DE5)),
  ];

  @override
  void didUpdateWidget(covariant DemoShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasCard.value = widget.settings.showCard;
    if (oldWidget.settings.tabCount != widget.settings.tabCount &&
        _controller.selectedIndex >= widget.settings.tabCount) {
      _controller.selectIndex(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hasCard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeds = _all.take(widget.settings.tabCount - 1).toList();
    final items = [
      for (final feed in feeds)
        LiquidGlassTabItem(icon: feed.icon, label: feed.label),
      const LiquidGlassTabItem(
        icon: CupertinoIcons.gear_solid,
        label: 'Settings',
      ),
    ];
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: LiquidGlassTabScaffold(
        // Recreate the host when the tab count changes so the IndexedStack
        // and the bar always agree on the item list.
        key: ValueKey(widget.settings.tabCount),
        controller: _controller,
        items: items,
        reduceMotion: widget.settings.reduceMotion,
        card: widget.settings.showCard ? const DemoCard() : null,
        tabBuilders: [
          for (final feed in feeds)
            (context) => DemoFeedPage(
              title: feed.label,
              seed: feed.seed,
              tabController: _controller,
            ),
          (context) => const DemoSettingsPage(),
        ],
      ),
    );
  }
}
