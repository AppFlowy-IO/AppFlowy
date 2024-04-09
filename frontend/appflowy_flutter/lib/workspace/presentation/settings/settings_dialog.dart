import 'package:flutter/material.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/feature_flag_page.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsDialog extends StatelessWidget {
  SettingsDialog(
    this.user, {
    required this.dismissDialog,
    required this.didLogout,
    required this.restartApp,
  }) : super(key: ValueKey(user.id));

  final VoidCallback dismissDialog;
  final VoidCallback didLogout;
  final VoidCallback restartApp;
  final UserProfilePB user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsDialogBloc>(
      create: (context) => getIt<SettingsDialogBloc>(param1: user)
        ..add(const SettingsDialogEvent.initial()),
      child: BlocBuilder<SettingsDialogBloc, SettingsDialogState>(
        builder: (context, state) => FlowyDialog(
          constraints: const BoxConstraints(minWidth: 564, maxHeight: 784),
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: SettingsMenu(
                      userProfile: user,
                      changeSelectedPage: (index) => context
                          .read<SettingsDialogBloc>()
                          .add(SettingsDialogEvent.setSelectedPage(index)),
                      currentPage: state.page,
                    ),
                  ),
                  Expanded(
                    child: getSettingsView(
                      state.page,
                      state.userProfile,
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
      case SettingsPage.account:
        return SettingsAccountView(
          userProfile: user,
          didLogout: didLogout,
          didLogin: dismissDialog,
        );
      case SettingsPage.workspace:
        return SettingsWorkspaceView(userProfile: user);
      // case SettingsPage.language:
      //   return const SettingsLanguageView();
      // case SettingsPage.files:
      //   return const SettingsFileSystemView();
      // case SettingsPage.user:
      //   return SettingsUserView(
      //     user,
      //     didLogin: dismissDialog,
      //     didLogout: didLogout,
      //     didOpenUser: restartApp,
      //   );
      // case SettingsPage.notifications:
      //   return const SettingsNotificationsView();
      // case SettingsPage.cloud:
      //   return SettingCloud(
      //     restartAppFlowy: () => restartApp(),
      //   );
      // case SettingsPage.shortcuts:
      //   return const SettingsCustomizeShortcutsWrapper();
      // case SettingsPage.member:
      //   return WorkspaceMembersPage(userProfile: user);
      case SettingsPage.featureFlags:
        return const FeatureFlagsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
