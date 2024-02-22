import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarWorkspace extends StatelessWidget {
  const SidebarWorkspace({
    super.key,
    required this.userProfile,
    required this.views,
  });

  final UserProfilePB userProfile;
  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserWorkspaceBloc>(
      create: (context) => UserWorkspaceBloc(userProfile: userProfile)
        ..add(
          const UserWorkspaceEvent.initial(),
        ),
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        builder: (context, state) => Row(
          children: [
            Expanded(
              child: _WorkspaceWrapper(
                userProfile: userProfile,
                currentWorkspace: state.currentWorkspace,
                workspaces: state.workspaces,
                child: _CurrentWorkspace(
                  currentWorkspace: state.currentWorkspace,
                ),
              ),
            ),
            UserSettingButton(userProfile: userProfile),
            const HSpace(4),
            NotificationButton(views: views),
          ],
        ),
      ),
    );
  }
}

class _CurrentWorkspace extends StatelessWidget {
  const _CurrentWorkspace({
    this.currentWorkspace,
  });

  final WorkspacePB? currentWorkspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO: Lucas.Xu. this is a temporary emoji.
        const EmojiText(
          emoji: '🐻',
          fontSize: 18,
        ),
        const HSpace(8),
        FlowyText.medium(
          currentWorkspace?.name ?? '',
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const FlowySvg(FlowySvgs.drop_menu_show_m),
      ],
    );
  }
}

class _WorkspaceWrapper extends StatelessWidget {
  const _WorkspaceWrapper({
    required this.userProfile,
    required this.currentWorkspace,
    required this.workspaces,
    required this.child,
  });

  final UserProfilePB userProfile;
  final WorkspacePB? currentWorkspace;
  final List<UserWorkspacePB> workspaces;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (workspaces.isEmpty) {
      return child;
    }

    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        direction: PopoverDirection.bottomWithCenterAligned,
        clickHandler: PopoverClickHandler.gestureDetector,
        popupBuilder: (_) {
          return BlocProvider<UserWorkspaceBloc>.value(
            value: context.read<UserWorkspaceBloc>(),
            child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
              builder: (context, state) {
                return _WorkspaceMenu(
                  userProfile: userProfile,
                  currentWorkspace: currentWorkspace,
                  workspaces: workspaces,
                );
              },
            ),
          );
        },
        child: child,
      );
    } else {
      // TODO: Lucas.Xu. mobile workspace menu
      return const Placeholder();
    }
  }
}

class _WorkspaceMenu extends StatelessWidget {
  const _WorkspaceMenu({
    required this.userProfile,
    required this.currentWorkspace,
    required this.workspaces,
  });

  final UserProfilePB userProfile;
  final WorkspacePB? currentWorkspace;
  final List<UserWorkspacePB> workspaces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // user email
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              FlowyText.medium(
                _getUserInfo(),
                fontSize: 12.0,
                overflow: TextOverflow.ellipsis,
                color: Theme.of(context).hintColor,
              ),
              const Spacer(),
              FlowyButton(
                useIntrinsicWidth: true,
                text: const FlowySvg(FlowySvgs.add_m),
                onTap: () {
                  // TODO: mock create workspace
                  context.read<UserWorkspaceBloc>().add(
                        const UserWorkspaceEvent.createWorkspace(
                          'Hello World',
                          'this is a fake workspace description.',
                        ),
                      );
                },
              ),
            ],
          ),
        ),
        for (final workspace in workspaces) ...[
          _WorkspaceMenuItem(
            workspace: workspace,
            isSelected: workspace.workspaceId == currentWorkspace?.id,
          ),
          const Divider(),
        ],
      ],
    );
  }

  String _getUserInfo() {
    if (userProfile.email.isNotEmpty) {
      return userProfile.email;
    }

    if (userProfile.name.isNotEmpty) {
      return userProfile.name;
    }

    return LocaleKeys.defaultUsername.tr();
  }
}

class _WorkspaceMenuItem extends StatelessWidget {
  const _WorkspaceMenuItem({
    required this.workspace,
    required this.isSelected,
  });

  final UserWorkspacePB workspace;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: () {
        if (!isSelected) {
          context.read<UserWorkspaceBloc>().add(
                UserWorkspaceEvent.openWorkspace(workspace.workspaceId),
              );
        }
      },
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      rightIcon: _buildRightIcon(context),
      text: FlowyText.medium(
        workspace.name,
        fontSize: 14.0,
        overflow: TextOverflow.ellipsis,
        color: isSelected ? null : Theme.of(context).hintColor,
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context) {
    final shouldDisableDelete = workspace.name == 'My Workspace';
    return GestureDetector(
      onTap: () {
        if (shouldDisableDelete) {
          showSnackBarMessage(
            context,
            'You cannot delete the default workspace.',
          );
          return;
        }

        context.read<UserWorkspaceBloc>().add(
              UserWorkspaceEvent.deleteWorkspace(workspace.workspaceId),
            );
      },
      child: FlowySvg(
        FlowySvgs.delete_s,
        size: const Size.square(16.0),
        color: isSelected ? null : Theme.of(context).hintColor,
      ),
    );
  }
}
