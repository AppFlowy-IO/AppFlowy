import 'package:app_flowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedViewIndex = 0;

  final List<Widget> settingsViews = const [
    SettingsAppearanceView(),
    SettingsLanguageView(),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: SizedBox(
        height: 600,
        width: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsPanelHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SettingsMenu(
                      changeSelectedIndex: (index) {
                        setState(() {
                          _selectedViewIndex = index;
                        });
                      },
                      currentIndex: _selectedViewIndex,
                    ),
                  ),
                  const VerticalDivider(),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: settingsViews[_selectedViewIndex],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPanelHeader extends StatelessWidget {
  const SettingsPanelHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        //TODO: Change to i10n
        'Settings',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
