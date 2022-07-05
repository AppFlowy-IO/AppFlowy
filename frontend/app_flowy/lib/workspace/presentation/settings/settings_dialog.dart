import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_settings_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatefulWidget {
  final UserProfile user;
  SettingsDialog(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedViewIndex = 0;

  Widget getSettingsView(int index, UserProfile user) {
    final List<Widget> settingsViews = [
      const SettingsAppearanceView(),
      const SettingsLanguageView(),
      SettingsSettingsView(user),
    ];
    return settingsViews[index];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<AppearanceSettingModel>(context, listen: true),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(
          LocaleKeys.settings_title.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 600,
            minWidth: 600,
            maxWidth: 1000,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
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
                child: getSettingsView(_selectedViewIndex, widget.user),
              )
            ],
          ),
        ),
      ),
    );
  }
}
