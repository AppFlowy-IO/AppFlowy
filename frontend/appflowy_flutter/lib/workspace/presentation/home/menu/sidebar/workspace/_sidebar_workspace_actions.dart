import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
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
  leave,
  divider,
}

class WorkspaceMoreActionList extends StatelessWidget {
  const WorkspaceMoreActionList({
    super.key,
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    final myRole = context.read<WorkspaceMemberBloc>().state.myRole;
    final actions = [];
    if (myRole.isOwner) {
      actions.add(WorkspaceMoreAction.rename);
      actions.add(WorkspaceMoreAction.divider);
      actions.add(WorkspaceMoreAction.delete);
    } else if (myRole.canLeave) {
      actions.add(WorkspaceMoreAction.leave);
    }
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    return PopoverActionList<_WorkspaceMoreActionWrapper>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: actions
          .map((e) => _WorkspaceMoreActionWrapper(e, workspace))
          .toList(),
      constraints: const BoxConstraints(minWidth: 220),
      buildChild: (controller) {
        return SizedBox.square(
          dimension: 24.0,
          child: FlowyButton(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            text: const FlowySvg(
              FlowySvgs.workspace_three_dots_s,
            ),
            onTap: () {
              controller.show();
            },
          ),
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
  Widget buildWithContext(
    BuildContext context,
    PopoverController controller,
    PopoverMutex? mutex,
  ) {
    if (inner == WorkspaceMoreAction.divider) {
      return const Divider();
    }

    return _buildActionButton(context, controller);
  }

  Widget _buildActionButton(
    BuildContext context,
    PopoverController controller,
  ) {
    return FlowyIconTextButton(
      leftIconBuilder: (onHover) => buildLeftIcon(context, onHover),
      iconPadding: 10.0,
      textBuilder: (onHover) => FlowyText.regular(
        name,
        fontSize: 14.0,
        figmaLineHeight: 18.0,
        color: [WorkspaceMoreAction.delete, WorkspaceMoreAction.leave]
                    .contains(inner) &&
                onHover
            ? Theme.of(context).colorScheme.error
            : null,
      ),
      margin: const EdgeInsets.all(6),
      onTap: () async {
        PopoverContainer.of(context).closeAll();

        final workspaceBloc = context.read<UserWorkspaceBloc>();
        switch (inner) {
          case WorkspaceMoreAction.divider:
            break;
          case WorkspaceMoreAction.delete:
            await showConfirmDeletionDialog(
              context: context,
              name: workspace.name,
              description: LocaleKeys.workspace_deleteWorkspaceHintText.tr(),
              onConfirm: () {
                workspaceBloc.add(
                  UserWorkspaceEvent.deleteWorkspace(workspace.workspaceId),
                );
              },
            );
          case WorkspaceMoreAction.rename:
            await NavigatorTextFieldDialog(
              title: LocaleKeys.workspace_renameWorkspace.tr(),
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
          case WorkspaceMoreAction.leave:
            await showConfirmDialog(
              context: context,
              title: LocaleKeys.workspace_leaveCurrentWorkspace.tr(),
              description:
                  LocaleKeys.workspace_leaveCurrentWorkspacePrompt.tr(),
              confirmLabel: LocaleKeys.button_yes.tr(),
              onConfirm: () {
                workspaceBloc.add(
                  UserWorkspaceEvent.leaveWorkspace(workspace.workspaceId),
                );
              },
            );
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
      case WorkspaceMoreAction.leave:
        return LocaleKeys.workspace_leaveCurrentWorkspace.tr();
      case WorkspaceMoreAction.divider:
        return '';
    }
  }

  Widget buildLeftIcon(BuildContext context, bool onHover) {
    switch (inner) {
      case WorkspaceMoreAction.delete:
        return FlowySvg(
          FlowySvgs.delete_s,
          color: onHover ? Theme.of(context).colorScheme.error : null,
        );
      case WorkspaceMoreAction.rename:
        return const FlowySvg(FlowySvgs.view_item_rename_s);
      case WorkspaceMoreAction.leave:
        return FlowySvg(
          FlowySvgs.logout_s,
          color: onHover ? Theme.of(context).colorScheme.error : null,
        );
      case WorkspaceMoreAction.divider:
        return const SizedBox.shrink();
    }
  }
}
