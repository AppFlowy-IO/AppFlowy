import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
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
    final List<Widget> children = [];
    for (var i = 0; i < workspaces.length; i++) {
      final workspace = workspaces[i];
      children.add(
        _WorkspaceMenuItem(
          key: ValueKey(workspace.workspaceId),
          userProfile: userProfile,
          workspace: workspace,
          showTopBorder: i == 0,
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
          final members = state.members;
          return FlowyOptionTile.text(
            content: Expanded(
              child: Padding(
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
                              members.length,
                            ),
                      fontSize: 10.0,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
              ),
            ),
            height: 60,
            showTopBorder: showTopBorder,
            leftIcon: WorkspaceIcon(
              enableEdit: false,
              iconSize: 26,
              workspace: workspace,
            ),
            trailing: workspace.workspaceId == currentWorkspace.workspaceId
                ? const FlowySvg(
                    FlowySvgs.m_blue_check_s,
                    blendMode: null,
                  )
                : null,
            onTap: () => onWorkspaceSelected(workspace),
          );
        },
      ),
    );
  }
}
