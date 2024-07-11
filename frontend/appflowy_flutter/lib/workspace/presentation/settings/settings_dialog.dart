import 'package:flutter/material.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_ai_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_billing_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_manage_data_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_shortcuts_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/feature_flag_page.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_page.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_notifications_view.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/setting_cloud.dart';

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
          width: MediaQuery.of(context).size.width * 0.7,
          constraints: const BoxConstraints(maxWidth: 784, minWidth: 564),
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
                      currentPage:
                          context.read<SettingsDialogBloc>().state.page,
                      member: context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspaceMember,
                    ),
                  ),
                  Expanded(
                    child: getSettingsView(
                      context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspace!
                          .workspaceId,
                      context.read<SettingsDialogBloc>().state.page,
                      context.read<SettingsDialogBloc>().state.userProfile,
                      context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspaceMember,
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

  Widget getSettingsView(
    String workspaceId,
    SettingsPage page,
    UserProfilePB user,
    WorkspaceMemberPB? member,
  ) {
    switch (page) {
      case SettingsPage.account:
        return SettingsAccountView(
          userProfile: user,
          didLogout: didLogout,
          didLogin: dismissDialog,
        );
      case SettingsPage.workspace:
        return SettingsWorkspaceView(
          userProfile: user,
          workspaceMember: member,
        );
      case SettingsPage.manageData:
        return SettingsManageDataView(userProfile: user);
      case SettingsPage.notifications:
        return const SettingsNotificationsView();
      case SettingsPage.cloud:
        return SettingCloud(restartAppFlowy: () => restartApp());
      case SettingsPage.shortcuts:
        return const SettingsShortcutsView();
      case SettingsPage.ai:
        if (user.authenticator == AuthenticatorPB.AppFlowyCloud) {
          return SettingsAIView(userProfile: user);
        } else {
          return const AIFeatureOnlySupportedWhenUsingAppFlowyCloud();
        }
      case SettingsPage.member:
        return WorkspaceMembersPage(
          userProfile: user,
          workspaceId: workspaceId,
        );
      case SettingsPage.plan:
        return SettingsPlanView(workspaceId: workspaceId, user: user);
      case SettingsPage.billing:
        return SettingsBillingView(workspaceId: workspaceId, user: user);
      case SettingsPage.featureFlags:
        return const FeatureFlagsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
