import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/loading.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/workspace_notifier.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
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

  final ValueNotifier<bool> onHover = ValueNotifier(false);
  int maxRetryCount = 3;
  int retryCount = 0;

  @override
  void initState() {
    super.initState();

    openWorkspaceNotifier.addListener(_openWorkspaceFromInvitation);
  }

  @override
  void dispose() {
    onHover.dispose();
    openWorkspaceNotifier.removeListener(_openWorkspaceFromInvitation);

    super.dispose();
  }

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
        return MouseRegion(
          onEnter: (_) => onHover.value = true,
          onExit: (_) => onHover.value = false,
          child: ValueListenableBuilder(
            valueListenable: onHover,
            builder: (_, onHover, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: onHover
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SidebarSwitchWorkspaceButton(
                        userProfile: widget.userProfile,
                        currentWorkspace: currentWorkspace,
                        isHover: onHover,
                      ),
                    ),
                    UserSettingButton(
                      userProfile: widget.userProfile,
                      isHover: onHover,
                    ),
                    const HSpace(8.0),
                    NotificationButton(isHover: onHover),
                    const HSpace(4.0),
                  ],
                ),
              );
            },
          ),
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

      case UserWorkspaceActionType.fetchWorkspaces:
      case UserWorkspaceActionType.none:
      case UserWorkspaceActionType.leave:
        message = null;
        break;
    }

    if (message != null) {
      showToastNotification(
        message: message,
        type: result.fold(
          (_) => ToastificationType.success,
          (_) => ToastificationType.error,
        ),
      );
    }
  }

  // This function is a workaround, when we support open the workspace from invitation deep link,
  // we should refactor the code here
  void _openWorkspaceFromInvitation() {
    final value = openWorkspaceNotifier.value;
    final workspaceId = value?.workspaceId;
    final email = value?.email;

    if (workspaceId == null) {
      Log.info('No workspace id to open');
      return;
    }

    if (email == null) {
      Log.info('Open workspace from invitation with no email');
      return;
    }

    final state = context.read<UserWorkspaceBloc>().state;
    final currentWorkspace = state.currentWorkspace;
    if (currentWorkspace?.workspaceId == workspaceId) {
      Log.info('Already in the workspace');
      return;
    }

    if (email != widget.userProfile.email) {
      Log.info(
        'Current user email: ${widget.userProfile.email} is not the same as the email in the invitation: $email',
      );
      return;
    }

    final openWorkspace = state.workspaces.firstWhereOrNull(
      (workspace) => workspace.workspaceId == workspaceId,
    );

    if (openWorkspace == null) {
      Log.error('Workspace not found, try to fetch workspaces');

      context.read<UserWorkspaceBloc>().add(
            UserWorkspaceEvent.fetchWorkspaces(
              initialWorkspaceId: workspaceId,
            ),
          );

      Future.delayed(
        Duration(milliseconds: 250 + retryCount * 250),
        () {
          if (retryCount >= maxRetryCount) {
            openWorkspaceNotifier.value = null;
            retryCount = 0;
            Log.error('Failed to open workspace from invitation');
            return;
          }

          retryCount++;
          _openWorkspaceFromInvitation();
        },
      );

      return;
    }

    context.read<UserWorkspaceBloc>().add(
          UserWorkspaceEvent.openWorkspace(
            workspaceId,
            openWorkspace.workspaceType,
          ),
        );

    openWorkspaceNotifier.value = null;
  }
}

class SidebarSwitchWorkspaceButton extends StatefulWidget {
  const SidebarSwitchWorkspaceButton({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
    this.isHover = false,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;
  final bool isHover;

  @override
  State<SidebarSwitchWorkspaceButton> createState() =>
      _SidebarSwitchWorkspaceButtonState();
}

class _SidebarSwitchWorkspaceButtonState
    extends State<SidebarSwitchWorkspaceButton> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<UserWorkspaceBloc>(),
      child: AppFlowyPopover(
        direction: PopoverDirection.bottomWithCenterAligned,
        offset: const Offset(0, 5),
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 600),
        margin: EdgeInsets.zero,
        animationDuration: Durations.short3,
        beginScaleFactor: 1.0,
        beginOpacity: 0.8,
        controller: _popoverController,
        triggerActions: PopoverTriggerFlags.none,
        onOpen: () {
          context
              .read<UserWorkspaceBloc>()
              .add(const UserWorkspaceEvent.fetchWorkspaces());
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
                return WorkspacesMenu(
                  userProfile: widget.userProfile,
                  currentWorkspace: currentWorkspace,
                  workspaces: workspaces,
                );
              },
            ),
          );
        },
        child: _SideBarSwitchWorkspaceButtonChild(
          currentWorkspace: widget.currentWorkspace,
          popoverController: _popoverController,
          isHover: widget.isHover,
        ),
      ),
    );
  }
}

class _SideBarSwitchWorkspaceButtonChild extends StatelessWidget {
  const _SideBarSwitchWorkspaceButtonChild({
    required this.popoverController,
    required this.currentWorkspace,
    required this.isHover,
  });

  final PopoverController popoverController;
  final UserWorkspacePB currentWorkspace;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.read<UserWorkspaceBloc>().add(
                const UserWorkspaceEvent.fetchWorkspaces(),
              );
          popoverController.show();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 30,
          child: Row(
            children: [
              const HSpace(4.0),
              WorkspaceIcon(
                workspace: currentWorkspace,
                iconSize: 26,
                fontSize: 16,
                emojiSize: 20,
                enableEdit: false,
                borderRadius: 8.0,
                figmaLineHeight: 18.0,
                showBorder: false,
                onSelected: (result) => context.read<UserWorkspaceBloc>().add(
                      UserWorkspaceEvent.updateWorkspaceIcon(
                        currentWorkspace.workspaceId,
                        result.emoji,
                      ),
                    ),
              ),
              const HSpace(6),
              Flexible(
                child: FlowyText.medium(
                  currentWorkspace.name,
                  color:
                      isHover ? Theme.of(context).colorScheme.onSurface : null,
                  overflow: TextOverflow.ellipsis,
                  withTooltip: true,
                  fontSize: 15.0,
                ),
              ),
              if (isHover) ...[
                const HSpace(4),
                FlowySvg(
                  FlowySvgs.workspace_drop_down_menu_show_s,
                  color:
                      isHover ? Theme.of(context).colorScheme.onSurface : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
