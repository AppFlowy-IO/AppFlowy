import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/sync_setting_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_system_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/flowy_svgs.g.dart';

const _dialogHorizontalPadding = EdgeInsets.symmetric(horizontal: 12);
const _contentInsetPadding = EdgeInsets.symmetric(vertical: 12.0);

class SettingsDialog extends StatelessWidget {
  final VoidCallback dismissDialog;
  final VoidCallback didLogout;
  final VoidCallback didOpenUser;
  final UserProfilePB user;

  SettingsDialog(
    this.user, {
    required this.dismissDialog,
    required this.didLogout,
    required this.didOpenUser,
    Key? key,
  }) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsDialogBloc>(
      create: (context) => getIt<SettingsDialogBloc>(param1: user)
        ..add(const SettingsDialogEvent.initial()),
      child: BlocBuilder<SettingsDialogBloc, SettingsDialogState>(
        builder: (context, state) => FlowyDialog(
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding:
                        _dialogHorizontalPadding * 2 + _contentInsetPadding,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        FlowyText(
                          LocaleKeys.settings_title.tr(),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const Spacer(),
                        FlowyIconButton(
                          onPressed: dismissDialog,
                          hoverColor: Theme.of(context).colorScheme.error,
                          icon: const FlowySvg(
                            FlowySvgs.close_s,
                            size: Size.square(40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: _dialogHorizontalPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(right: 12),
                            width: 200,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: SettingsMenu(
                              changeSelectedPage: (index) => context
                                  .read<SettingsDialogBloc>()
                                  .add(
                                    SettingsDialogEvent.setSelectedPage(index),
                                  ),
                              currentPage:
                                  context.read<SettingsDialogBloc>().state.page,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: _contentInsetPadding,
                              child: getSettingsView(
                                context.read<SettingsDialogBloc>().state.page,
                                context
                                    .read<SettingsDialogBloc>()
                                    .state
                                    .userProfile,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getSettingsView(SettingsPage page, UserProfilePB user) {
    switch (page) {
      case SettingsPage.appearance:
        return const SettingsAppearanceView();
      case SettingsPage.language:
        return const SettingsLanguageView();
      case SettingsPage.files:
        return const SettingsFileSystemView();
      case SettingsPage.user:
        return SettingsUserView(
          user,
          didLogin: () => dismissDialog(),
          didLogout: didLogout,
          didOpenUser: didOpenUser,
        );
      case SettingsPage.syncSetting:
        return SyncSettingView(userId: user.id.toString());
      case SettingsPage.shortcuts:
        return const SettingsCustomizeShortcutsWrapper();
      default:
        return Container();
    }
  }
}
