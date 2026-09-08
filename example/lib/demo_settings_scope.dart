import 'package:flutter/widgets.dart';

import 'demo_settings.dart';

/// Makes the [DemoSettingsController] reachable from the settings tab.
class DemoSettingsScope extends InheritedNotifier<DemoSettingsController> {
  const DemoSettingsScope({
    super.key,
    required DemoSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static DemoSettingsController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DemoSettingsScope>()!
      .notifier!;
}
