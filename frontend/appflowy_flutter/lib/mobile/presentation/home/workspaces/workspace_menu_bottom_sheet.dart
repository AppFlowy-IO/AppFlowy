import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

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
        FlowyOptionTile.text(
          text: workspace.name,
          showTopBorder: i == 0,
          leftIcon: WorkspaceIcon(
            enableEdit: false,
            iconSize: 22,
            workspace: workspace,
          ),
          trailing: workspace.workspaceId == currentWorkspace.workspaceId
              ? const FlowySvg(
                  FlowySvgs.m_blue_check_s,
                  blendMode: null,
                )
              : null,
          onTap: () => onWorkspaceSelected(workspace),
        ),
      );
    }
    return Column(
      children: children,
    );
  }
}
