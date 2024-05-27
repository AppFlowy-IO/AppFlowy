import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
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
  const SidebarWorkspace({super.key, required this.userProfile});

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
            const HSpace(8),
            const NotificationButton(),
            const HSpace(4),
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

class SidebarSwitchWorkspaceButton extends StatefulWidget {
  const SidebarSwitchWorkspaceButton({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;

  @override
  State<SidebarSwitchWorkspaceButton> createState() =>
      _SidebarSwitchWorkspaceButtonState();
}

class _SidebarSwitchWorkspaceButtonState
    extends State<SidebarSwitchWorkspaceButton> {
  final ValueNotifier<bool> _isWorkSpaceMenuExpanded = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 5),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 600),
      onOpen: () {
        _isWorkSpaceMenuExpanded.value = true;
        context
            .read<UserWorkspaceBloc>()
            .add(const UserWorkspaceEvent.fetchWorkspaces());
      },
      onClose: () {
        _isWorkSpaceMenuExpanded.value = false;
        Log.info('close workspace menu');
      },
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
                userProfile: widget.userProfile,
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
              );
            },
          ),
        );
      },
      child: FlowyButton(
        margin: EdgeInsets.zero,
        text: Row(
          children: [
            const HSpace(6.0),
            SizedBox(
              width: 16.0,
              child: WorkspaceIcon(
                workspace: widget.currentWorkspace,
                iconSize: 16,
                fontSize: 10,
                enableEdit: false,
                onSelected: (result) => context.read<UserWorkspaceBloc>().add(
                      UserWorkspaceEvent.updateWorkspaceIcon(
                        widget.currentWorkspace.workspaceId,
                        result.emoji,
                      ),
                    ),
              ),
            ),
            const HSpace(10),
            Flexible(
              child: FlowyText.medium(
                widget.currentWorkspace.name,
                overflow: TextOverflow.ellipsis,
                withTooltip: true,
              ),
            ),
            const HSpace(4),
            ValueListenableBuilder(
              valueListenable: _isWorkSpaceMenuExpanded,
              builder: (context, value, _) => FlowySvg(
                value
                    ? FlowySvgs.workspace_drop_down_menu_hide_s
                    : FlowySvgs.workspace_drop_down_menu_show_s,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
