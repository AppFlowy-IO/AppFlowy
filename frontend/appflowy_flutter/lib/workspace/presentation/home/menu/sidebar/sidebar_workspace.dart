import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserWorkspaceBloc>(
          create: (_) => UserWorkspaceBloc(userProfile: userProfile)
            ..add(const UserWorkspaceEvent.fetchWorkspaces()),
        ),
        BlocProvider<WorkspaceMemberBloc>(
          create: (_) => WorkspaceMemberBloc(userProfile: userProfile)
            ..add(const WorkspaceMemberEvent.getWorkspaceMembers()),
        ),
      ],
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (_, __) {
          return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
            builder: (context, state) {
              final currentWorkspace = state.currentWorkspace;
              // todo: show something if there is no workspace
              if (currentWorkspace == null) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  Expanded(
                    child: _WorkspaceWrapper(
                      userProfile: userProfile,
                      child: _CurrentWorkspace(
                        currentWorkspace: currentWorkspace,
                      ),
                    ),
                  ),
                  UserSettingButton(userProfile: userProfile),
                  const HSpace(4),
                  NotificationButton(views: views),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CurrentWorkspace extends StatelessWidget {
  const _CurrentWorkspace({
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HSpace(4.0),
        SizedBox(
          width: 24.0,
          child: _WorkspaceIcon(workspace: currentWorkspace),
        ),
        const HSpace(8),
        FlowyText.medium(
          currentWorkspace.name,
          overflow: TextOverflow.ellipsis,
        ),
        const FlowySvg(FlowySvgs.drop_menu_show_m),
      ],
    );
  }
}

class _WorkspaceWrapper extends StatelessWidget {
  const _WorkspaceWrapper({
    required this.userProfile,
    required this.child,
  });

  final UserProfilePB userProfile;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        direction: PopoverDirection.bottomWithCenterAligned,
        clickHandler: PopoverClickHandler.gestureDetector,
        offset: const Offset(0, 10),
        mutex: PopoverMutex(),
        popupBuilder: (_) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<UserWorkspaceBloc>.value(
                value: context.read<UserWorkspaceBloc>(),
              ),
              BlocProvider<WorkspaceMemberBloc>.value(
                value: context.read<WorkspaceMemberBloc>(),
              ),
            ],
            child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
              builder: (context, state) {
                final currentWorkspace = state.currentWorkspace;
                final workspaces = state.workspaces;
                if (currentWorkspace == null || workspaces.isEmpty) {
                  return const SizedBox.shrink();
                }
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
  final UserWorkspacePB currentWorkspace;
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
            isSelected: workspace.workspaceId == currentWorkspace.workspaceId,
          ),
          const VSpace(4.0),
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
      iconPadding: 8.0,
      leftIconSize: const Size.square(28),
      leftIcon: _WorkspaceIcon(
        workspace: workspace,
      ),
      rightIcon: _buildRightIcon(context),
      text: FlowyText.medium(
        workspace.name,
        fontSize: 14.0,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context) {
    // only the owner can update or delete workspace.
    // only show the more action button when the workspace is selected.
    if (!isSelected ||
        !context.read<WorkspaceMemberBloc>().state.myRole.isOwner) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        WorkspaceMoreActionList(workspace: workspace),
        const FlowySvg(
          FlowySvgs.blue_check_s,
          blendMode: null,
        ),
      ],
    );
  }
}

class _WorkspaceIcon extends StatelessWidget {
  const _WorkspaceIcon({
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    // TODO: support icon later
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorGenerator.generateColorFromString(workspace.name),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyText(
        workspace.name.substring(0, 1).toUpperCase(),
        fontSize: 16,
        color: Colors.black,
      ),
    );
  }
}
