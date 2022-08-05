import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:app_flowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:app_flowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatelessWidget {
  final UserProfilePB user;
  SettingsDialog(this.user, {Key? key}) : super(key: ValueKey(user.id));

  Widget getSettingsView(int index, UserProfilePB user) {
    final List<Widget> settingsViews = [
      const SettingsAppearanceView(),
      const SettingsLanguageView(),
      SettingsUserView(user),
    ];
    return settingsViews[index];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsDialogBloc>(
        create: (context) => getIt<SettingsDialogBloc>(param1: user)..add(const SettingsDialogEvent.initial()),
        child: BlocBuilder<SettingsDialogBloc, SettingsDialogState>(
            builder: (context, state) => ChangeNotifierProvider.value(
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
                                context.read<SettingsDialogBloc>().add(SettingsDialogEvent.setViewIndex(index));
                              },
                              currentIndex: context.read<SettingsDialogBloc>().state.viewIndex,
                            ),
                          ),
                          const VerticalDivider(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: getSettingsView(context.read<SettingsDialogBloc>().state.viewIndex,
                                context.read<SettingsDialogBloc>().state.userProfile),
                          )
                        ],
                      ),
                    ),
                  ),
                )));
  }
}
