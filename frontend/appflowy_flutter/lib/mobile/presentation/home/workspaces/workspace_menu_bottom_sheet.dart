import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Only works on mobile.
class MobileWorkspaceMenu extends StatelessWidget {
  const MobileWorkspaceMenu({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
    required this.workspaces,
    required this.onWorkspaceSelected,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB currentWorkspace;
  final List<UserWorkspacePB> workspaces;
  final void Function(UserWorkspacePB workspace) onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _WorkspaceUserItem(userProfile: userProfile),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Divider(height: 0.5),
      ),
    ];
    for (var i = 0; i < workspaces.length; i++) {
      final workspace = workspaces[i];
      children.add(
        _WorkspaceMenuItem(
          key: ValueKey(workspace.workspaceId),
          userProfile: userProfile,
          workspace: workspace,
          showTopBorder: false,
          currentWorkspace: currentWorkspace,
          onWorkspaceSelected: onWorkspaceSelected,
        ),
      );
    }
    return Column(
      children: children,
    );
  }
}

class _WorkspaceUserItem extends StatelessWidget {
  const _WorkspaceUserItem({required this.userProfile});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).isLightMode
        ? const Color(0x99333333)
        : const Color(0x99CCCCCC);
    return FlowyOptionTile.text(
      height: 32,
      showTopBorder: false,
      showBottomBorder: false,
      content: Expanded(
        child: Padding(
          padding: const EdgeInsets.only(),
          child: FlowyText(
            userProfile.email,
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _WorkspaceMenuItem extends StatelessWidget {
  const _WorkspaceMenuItem({
    super.key,
    required this.userProfile,
    required this.workspace,
    required this.showTopBorder,
    required this.currentWorkspace,
    required this.onWorkspaceSelected,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB workspace;
  final bool showTopBorder;
  final UserWorkspacePB currentWorkspace;
  final void Function(UserWorkspacePB workspace) onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      height: 60,
      showTopBorder: showTopBorder,
      showBottomBorder: false,
      leftIcon: _WorkspaceMenuItemIcon(workspace: workspace),
      trailing: _WorkspaceMenuItemTrailing(
        workspace: workspace,
        currentWorkspace: currentWorkspace,
      ),
      onTap: () => onWorkspaceSelected(workspace),
      content: Expanded(
        child: _WorkspaceMenuItemContent(
          userProfile: userProfile,
          workspace: workspace,
        ),
      ),
    );
  }
}

// - Workspace name
// - Workspace member count
class _WorkspaceMenuItemContent extends StatelessWidget {
  const _WorkspaceMenuItemContent({
    required this.userProfile,
    required this.workspace,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkspaceMemberBloc(
        userProfile: userProfile,
        workspace: workspace,
      )..add(const WorkspaceMemberEvent.initial()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlowyText(
                  workspace.name,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                FlowyText(
                  state.isLoading
                      ? ''
                      : LocaleKeys.settings_appearance_members_membersCount
                          .plural(
                          state.members.length,
                        ),
                  fontSize: 10.0,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkspaceMenuItemIcon extends StatelessWidget {
  const _WorkspaceMenuItemIcon({
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: WorkspaceIcon(
        enableEdit: false,
        iconSize: 26,
        fontSize: 16.0,
        figmaLineHeight: 16.0,
        workspace: workspace,
        onSelected: (result) => context.read<UserWorkspaceBloc>().add(
              UserWorkspaceEvent.updateWorkspaceIcon(
                workspace.workspaceId,
                result.emoji,
              ),
            ),
      ),
    );
  }
}

class _WorkspaceMenuItemTrailing extends StatelessWidget {
  const _WorkspaceMenuItemTrailing({
    required this.workspace,
    required this.currentWorkspace,
  });

  final UserWorkspacePB workspace;
  final UserWorkspacePB currentWorkspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // show the check icon if the workspace is the current workspace
        if (workspace.workspaceId == currentWorkspace.workspaceId)
          const FlowySvg(
            FlowySvgs.m_blue_check_s,
            blendMode: null,
          ),
      ],
    );
  }
}
