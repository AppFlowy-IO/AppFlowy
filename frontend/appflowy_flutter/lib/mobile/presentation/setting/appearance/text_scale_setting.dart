import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/font_size_stepper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:scaled_app/scaled_app.dart';

import '../setting.dart';

const int _divisions = 4;
const double _minMobileScaleFactor = 0.8;
const double _maxMobileScaleFactor = 1.2;

class DisplaySizeSetting extends StatefulWidget {
  const DisplaySizeSetting({
    super.key,
  });

  @override
  State<DisplaySizeSetting> createState() => _DisplaySizeSettingState();
}

class _DisplaySizeSettingState extends State<DisplaySizeSetting> {
  double scaleFactor = 1.0;
  final windowSizeManager = WindowSizeManager();

  @override
  void initState() {
    super.initState();
    windowSizeManager.getScaleFactor().then((v) {
      if (v != scaleFactor && mounted) {
        setState(() {
          scaleFactor = v;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_displaySize.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            scaleFactor.toStringAsFixed(2),
            color: theme.colorScheme.onSurface,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showDragHandle: true,
          showDivider: false,
          title: LocaleKeys.settings_appearance_displaySize.tr(),
          builder: (context) {
            return FontSizeStepper(
              value: scaleFactor,
              minimumValue: _minMobileScaleFactor,
              maximumValue: _maxMobileScaleFactor,
              divisions: _divisions,
              onChanged: (newScaleFactor) async {
                await _setScale(newScaleFactor);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _setScale(double value) async {
    if (FlowyRunner.currentMode == IntegrationMode.integrationTest) {
      // The integration test will fail if we check the scale factor in the test.
      // #0      ScaledWidgetsFlutterBinding.Eval ()
      // #1      ScaledWidgetsFlutterBinding.instance (package:scaled_app/scaled_app.dart:66:62)
      // ignore: invalid_use_of_visible_for_testing_member
      appflowyScaleFactor = value;
    } else {
      ScaledWidgetsFlutterBinding.instance.scaleFactor = (_) => value;
    }
    if (mounted) {
      setState(() {
        scaleFactor = value;
      });
    }
    await windowSizeManager.setScaleFactor(value);
  }
}
