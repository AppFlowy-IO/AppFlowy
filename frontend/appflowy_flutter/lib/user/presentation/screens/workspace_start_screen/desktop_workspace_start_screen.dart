import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            _renderBody(workspaceState),
            _renderCreateButton(context),
          ],
        ),
      ),
    );
  }
}

Widget _renderBody(WorkspaceState state) {
  final body = state.successOrFailure.fold(
    (_) => _renderList(state.workspaces),
    (error) => FlowyErrorPage.message(
      error.toString(),
      howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
    ),
  );
  return body;
}

Widget _renderCreateButton(BuildContext context) {
  return SizedBox(
    width: 200,
    height: 40,
    child: FlowyTextButton(
      LocaleKeys.workspace_create.tr(),
      fontSize: 14,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onPressed: () {
        context.read<WorkspaceBloc>().add(
              WorkspaceEvent.createWorkspace(
                LocaleKeys.workspace_hint.tr(),
                "",
              ),
            );
      },
    ),
  );
}

Widget _renderList(List<WorkspacePB> workspaces) {
  return Expanded(
    child: StyledListView(
      itemBuilder: (BuildContext context, int index) {
        final workspace = workspaces[index];
        return _WorkspaceItem(
          workspace: workspace,
          onPressed: (workspace) => _handleOnPress(context, workspace),
        );
      },
      itemCount: workspaces.length,
    ),
  );
}

void _handleOnPress(BuildContext context, WorkspacePB workspace) {
  context.read<WorkspaceBloc>().add(WorkspaceEvent.openWorkspace(workspace));

  Navigator.of(context).pop(workspace.id);
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
