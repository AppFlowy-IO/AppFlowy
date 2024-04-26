import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarWorkspace extends StatefulWidget {
  const SidebarWorkspace({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SidebarWorkspace> createState() => _SidebarWorkspaceState();
}

class _SidebarWorkspaceState extends State<SidebarWorkspace> {
  Loading? loadingIndicator;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserWorkspaceBloc, UserWorkspaceState>(
      listenWhen: (previous, current) =>
          previous.actionResult != current.actionResult,
      listener: _showResultDialog,
      builder: (context, state) {
        final currentWorkspace = state.currentWorkspace;
        if (currentWorkspace == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            Expanded(
              child: SidebarSwitchWorkspaceButton(
                userProfile: widget.userProfile,
                currentWorkspace: currentWorkspace,
              ),
            ),
            UserSettingButton(userProfile: widget.userProfile),
            const HSpace(4),
            const NotificationButton(),
          ],
        );
      },
    );
  }

  void _showResultDialog(BuildContext context, UserWorkspaceState state) {
    final actionResult = state.actionResult;
    if (actionResult == null) {
      return;
    }

    final actionType = actionResult.actionType;
    final result = actionResult.result;
    final isLoading = actionResult.isLoading;

    if (isLoading) {
      loadingIndicator ??= Loading(context)..start();
      return;
    } else {
      loadingIndicator?.stop();
      loadingIndicator = null;
    }

    if (result == null) {
      return;
    }

    result.onFailure((f) {
      Log.error(
        '[Workspace] Failed to perform ${actionType.toString()} action: $f',
      );
    });

    // show a confirmation dialog if the action is create and the result is LimitExceeded failure
    if (actionType == UserWorkspaceActionType.create &&
        result.isFailure &&
        result.getFailure().code == ErrorCode.WorkspaceLimitExceeded) {
      showDialog(
        context: context,
        builder: (context) => NavigatorOkCancelDialog(
          message: LocaleKeys.workspace_createLimitExceeded.tr(),
        ),
      );
      return;
    }

    final String? message;
    switch (actionType) {
      case UserWorkspaceActionType.create:
        message = result.fold(
          (s) => LocaleKeys.workspace_createSuccess.tr(),
          (e) => '${LocaleKeys.workspace_createFailed.tr()}: ${e.msg}',
        );
        break;
      case UserWorkspaceActionType.delete:
        message = result.fold(
          (s) => LocaleKeys.workspace_deleteSuccess.tr(),
          (e) => '${LocaleKeys.workspace_deleteFailed.tr()}: ${e.msg}',
        );
        break;
      case UserWorkspaceActionType.open:
        message = result.fold(
          (s) => LocaleKeys.workspace_openSuccess.tr(),
          (e) => '${LocaleKeys.workspace_openFailed.tr()}: ${e.msg}',
        );
        break;
      case UserWorkspaceActionType.updateIcon:
        message = result.fold(
          (s) => LocaleKeys.workspace_updateIconSuccess.tr(),
          (e) => '${LocaleKeys.workspace_updateIconFailed.tr()}: ${e.msg}',
        );
        break;
      case UserWorkspaceActionType.rename:
        message = result.fold(
          (s) => LocaleKeys.workspace_renameSuccess.tr(),
          (e) => '${LocaleKeys.workspace_renameFailed.tr()}: ${e.msg}',
        );
        break;
      case UserWorkspaceActionType.none:
      case UserWorkspaceActionType.fetchWorkspaces:
      case UserWorkspaceActionType.leave:
        message = null;
        break;
    }

    if (message != null) {
      showSnackBarMessage(context, message);
    }
  }
}

class SidebarSwitchWorkspaceButton extends StatelessWidget {
  const SidebarSwitchWorkspaceButton({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 10),
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 600),
      onOpen: () => context
          .read<UserWorkspaceBloc>()
          .add(const UserWorkspaceEvent.fetchWorkspaces()),
      onClose: () => Log.info('close workspace menu'),
      popupBuilder: (_) {
        return BlocProvider<UserWorkspaceBloc>.value(
          value: context.read<UserWorkspaceBloc>(),
          child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
            builder: (context, state) {
              final currentWorkspace = state.currentWorkspace;
              final workspaces = state.workspaces;
              if (currentWorkspace == null) {
                return const SizedBox.shrink();
              }
              Log.info('open workspace menu');
              return WorkspacesMenu(
                userProfile: userProfile,
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
              );
            },
          ),
        );
      },
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(vertical: 8),
        text: Row(
          children: [
            const HSpace(2.0),
            SizedBox.square(
              dimension: 30.0,
              child: WorkspaceIcon(
                workspace: currentWorkspace,
                iconSize: 20,
                enableEdit: false,
              ),
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText.medium(
                currentWorkspace.name,
                overflow: TextOverflow.ellipsis,
                withTooltip: true,
              ),
            ),
            const FlowySvg(FlowySvgs.drop_menu_show_m),
          ],
        ),
      ),
    );
  }
}
