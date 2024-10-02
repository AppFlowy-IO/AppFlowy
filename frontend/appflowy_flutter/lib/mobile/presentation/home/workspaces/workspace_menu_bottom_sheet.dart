import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/navigator_context_exntesion.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_workspace_menu.dart';
import 'workspace_more_options.dart';

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
    // user profile
    final List<Widget> children = [
      _WorkspaceUserItem(userProfile: userProfile),
      _buildDivider(),
    ];

    // workspace list
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

    // create workspace button
    children.addAll([
      _buildDivider(),
      const _CreateWorkspaceButton(),
    ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Divider(height: 0.5),
    );
  }
}

class _CreateWorkspaceButton extends StatelessWidget {
  const _CreateWorkspaceButton();

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      height: 60,
      showTopBorder: false,
      showBottomBorder: false,
      leftIcon: _buildLeftIcon(context),
      onTap: () => _showCreateWorkspaceBottomSheet(context),
      content: Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: FlowyText.medium(
            LocaleKeys.workspace_create.tr(),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showCreateWorkspaceBottomSheet(BuildContext context) {
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: LocaleKeys.workspace_create.tr(),
      showCloseButton: true,
      showDragHandle: true,
      showDivider: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      builder: (bottomSheetContext) {
        return EditWorkspaceNameBottomSheet(
          type: EditWorkspaceNameType.create,
          workspaceName: 'My Workspace',
          onSubmitted: (name) {
            // create a new workspace
            Log.info('create a new workspace: $name');
            bottomSheetContext.popToHome();

            context.read<UserWorkspaceBloc>().add(
                  UserWorkspaceEvent.createWorkspace(
                    name,
                  ),
                );
          },
        );
      },
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x01717171).withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: const FlowySvg(FlowySvgs.add_workspace_s),
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
    return BlocProvider(
      create: (_) => WorkspaceMemberBloc(
        userProfile: userProfile,
        workspace: workspace,
      )..add(const WorkspaceMemberEvent.initial()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
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
                workspace: workspace,
              ),
            ),
          );
        },
      ),
    );
  }
}

// - Workspace name
// - Workspace member count
class _WorkspaceMenuItemContent extends StatelessWidget {
  const _WorkspaceMenuItemContent({
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
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
            context.read<WorkspaceMemberBloc>().state.isLoading
                ? ''
                : LocaleKeys.settings_appearance_members_membersCount.plural(
                    context.read<WorkspaceMemberBloc>().state.members.length,
                  ),
            fontSize: 10.0,
            color: Theme.of(context).hintColor,
          ),
        ],
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
    const iconSize = Size.square(20);
    return Row(
      children: [
        // show the check icon if the workspace is the current workspace
        if (workspace.workspaceId == currentWorkspace.workspaceId)
          const FlowySvg(
            FlowySvgs.m_blue_check_s,
            size: iconSize,
            blendMode: null,
          ),
        const HSpace(15.0),
        // more options button
        AnimatedGestureDetector(
          onTapUp: () => _showMoreOptions(context),
          child: const FlowySvg(
            FlowySvgs.workspace_three_dots_s,
            size: iconSize,
            blendMode: null,
          ),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    final actions =
        context.read<WorkspaceMemberBloc>().state.myRole == AFRolePB.Owner
            ? [
                // only the owner can update workspace properties
                WorkspaceMenuMoreOption.rename,
                WorkspaceMenuMoreOption.invite,
                WorkspaceMenuMoreOption.delete,
              ]
            : [
                WorkspaceMenuMoreOption.leave,
              ];

    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (bottomSheetContext) {
        return WorkspaceMenuMoreOptions(
          actions: actions,
          onAction: (action) => _onActions(context, bottomSheetContext, action),
        );
      },
    );
  }

  void _onActions(
    BuildContext context,
    BuildContext bottomSheetContext,
    WorkspaceMenuMoreOption action,
  ) {
    Log.info('execute action in workspace menu bottom sheet: $action');

    switch (action) {
      case WorkspaceMenuMoreOption.rename:
        _showRenameWorkspaceBottomSheet(context);
        break;
      case WorkspaceMenuMoreOption.invite:
        _pushToInviteMembersPage(context);
        break;
      case WorkspaceMenuMoreOption.delete:
        _deleteWorkspace(context, bottomSheetContext);
        break;
      case WorkspaceMenuMoreOption.leave:
        _leaveWorkspace(context, bottomSheetContext);
        break;
    }
  }

  void _pushToInviteMembersPage(BuildContext context) {
    // todo: implement later
  }

  void _showRenameWorkspaceBottomSheet(BuildContext context) {
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: LocaleKeys.workspace_renameWorkspace.tr(),
      showCloseButton: true,
      showDragHandle: true,
      showDivider: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      builder: (bottomSheetContext) {
        return EditWorkspaceNameBottomSheet(
          type: EditWorkspaceNameType.edit,
          workspaceName: workspace.name,
          onSubmitted: (name) {
            // rename the workspace
            Log.info('rename the workspace: $name');
            bottomSheetContext.popToHome();

            context.read<UserWorkspaceBloc>().add(
                  UserWorkspaceEvent.renameWorkspace(
                    workspace.workspaceId,
                    name,
                  ),
                );
          },
        );
      },
    );
  }

  void _deleteWorkspace(BuildContext context, BuildContext bottomSheetContext) {
    context.read<UserWorkspaceBloc>().add(
          UserWorkspaceEvent.deleteWorkspace(
            workspace.workspaceId,
          ),
        );

    bottomSheetContext.popToHome();
  }

  void _leaveWorkspace(BuildContext context, BuildContext bottomSheetContext) {
    context.read<UserWorkspaceBloc>().add(
          UserWorkspaceEvent.leaveWorkspace(
            workspace.workspaceId,
          ),
        );

    bottomSheetContext.popToHome();
  }
}
