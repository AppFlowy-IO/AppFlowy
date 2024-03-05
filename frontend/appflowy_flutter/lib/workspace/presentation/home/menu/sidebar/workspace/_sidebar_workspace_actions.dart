import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum WorkspaceMoreAction {
  rename,
  delete,
}

class WorkspaceMoreActionList extends StatelessWidget {
  const WorkspaceMoreActionList({
    super.key,
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_WorkspaceMoreActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: WorkspaceMoreAction.values
          .map((e) => _WorkspaceMoreActionWrapper(e, workspace))
          .toList(),
      buildChild: (controller) {
        return FlowyButton(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          useIntrinsicWidth: true,
          text: const FlowySvg(
            FlowySvgs.three_dots_vertical_s,
          ),
          onTap: () {
            controller.show();
          },
        );
      },
      onSelected: (action, controller) {},
    );
  }
}

class _WorkspaceMoreActionWrapper extends CustomActionCell {
  _WorkspaceMoreActionWrapper(this.inner, this.workspace);

  final WorkspaceMoreAction inner;
  final UserWorkspacePB workspace;

  @override
  Widget buildWithContext(BuildContext context) {
    return FlowyButton(
      text: FlowyText(
        name,
        color: inner == WorkspaceMoreAction.delete
            ? Theme.of(context).colorScheme.error
            : null,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      onTap: () async {
        PopoverContainer.of(context).closeAll();

        final workspaceBloc = context.read<UserWorkspaceBloc>();
        switch (inner) {
          case WorkspaceMoreAction.delete:
            await NavigatorAlertDialog(
              title: LocaleKeys.workspace_deleteWorkspaceHintText.tr(),
              confirm: () {
                workspaceBloc.add(
                  UserWorkspaceEvent.deleteWorkspace(workspace.workspaceId),
                );
              },
            ).show(context);
          case WorkspaceMoreAction.rename:
            await NavigatorTextFieldDialog(
              title: LocaleKeys.workspace_create.tr(),
              value: workspace.name,
              hintText: '',
              autoSelectAllText: true,
              onConfirm: (name, context) async {
                workspaceBloc.add(
                  UserWorkspaceEvent.renameWorkspace(
                    workspace.workspaceId,
                    name,
                  ),
                );
              },
            ).show(context);
        }
      },
    );
  }

  String get name {
    switch (inner) {
      case WorkspaceMoreAction.delete:
        return LocaleKeys.button_delete.tr();
      case WorkspaceMoreAction.rename:
        return LocaleKeys.button_rename.tr();
    }
  }
}
