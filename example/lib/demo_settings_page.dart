import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';

import 'demo_settings_scope.dart';

/// Switches for everything the bar adapts to.
class DemoSettingsPage extends StatelessWidget {
  const DemoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DemoSettingsScope.of(context);
    final settings = controller.value;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        MediaQuery.paddingOf(context).top + 16,
        0,
        LiquidGlassTabBar.estimatedDockedHeight +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      children: [
        SwitchListTile(
          title: const Text('Dark mode'),
          value: settings.dark,
          onChanged: (v) => controller.update((s) => s.copyWith(dark: v)),
        ),
        SwitchListTile(
          title: const Text('Right-to-left'),
          value: settings.rtl,
          onChanged: (v) => controller.update((s) => s.copyWith(rtl: v)),
        ),
        SwitchListTile(
          title: const Text('Show card'),
          subtitle: const Text('Without a card the bar never splits'),
          value: settings.showCard,
          onChanged: (v) => controller.update((s) => s.copyWith(showCard: v)),
        ),
        SwitchListTile(
          title: const Text('Reduce motion'),
          value: settings.reduceMotion,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(reduceMotion: v)),
        ),
        ListTile(
          title: Text('Text scale ${settings.textScale.toStringAsFixed(1)}'),
          subtitle: Slider(
            min: 1,
            max: 2,
            divisions: 10,
            value: settings.textScale,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(textScale: v)),
          ),
        ),
        ListTile(
          title: const Text('Tabs'),
          subtitle: SegmentedButton<int>(
            segments: [
              for (var n = 2; n <= 6; n++)
                ButtonSegment(value: n, label: Text('$n')),
            ],
            selected: {settings.tabCount},
            onSelectionChanged: (v) =>
                controller.update((s) => s.copyWith(tabCount: v.first)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Scroll a feed down to split the bar, up to dock it. Press and '
            'slide along the bar to move the lens; release to select. Re-tap '
            'the current tab to scroll it to the top.',
          ),
        ),
      ],
    );
  }
}
