import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/util/util.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DesktopWorkspaceStartScreen extends StatelessWidget {
  const DesktopWorkspaceStartScreen({super.key, required this.workspaceState});

  final WorkspaceState workspaceState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          children: [
            _WorkspaceList(
              workspaces: workspaceState.workspaces,
            ),
            const _CreateWorkspaceButton(),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceList extends StatelessWidget {
  const _WorkspaceList({
    Key? key,
    required this.workspaces,
  }) : super(key: key);

  final List<WorkspacePB> workspaces;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StyledListView(
        itemBuilder: (BuildContext context, int index) {
          final workspace = workspaces[index];
          return _WorkspaceItem(
            workspace: workspace,
            onPressed: (workspace) => popToWorkspace(context, workspace),
          );
        },
        itemCount: workspaces.length,
      ),
    );
  }
}

class _WorkspaceItem extends StatelessWidget {
  final WorkspacePB workspace;
  final void Function(WorkspacePB workspace) onPressed;
  const _WorkspaceItem({
    Key? key,
    required this.workspace,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FlowyTextButton(
        workspace.name,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        fontSize: 14,
        onPressed: () => onPressed(workspace),
      ),
    );
  }
}

class _CreateWorkspaceButton extends StatelessWidget {
  const _CreateWorkspaceButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: FlowyTextButton(
        LocaleKeys.workspace_create.tr(),
        fontSize: 14,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onPressed: () {
          createWorkspace(context);
        },
      ),
    );
  }
}
