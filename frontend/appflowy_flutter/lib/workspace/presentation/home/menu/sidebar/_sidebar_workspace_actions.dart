import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum WorkspaceMoreAction {
  delete,
  rename,
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
      asBarrier: true,
      popoverMutex: PopoverMutex(),
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: WorkspaceMoreAction.values
          .map((e) => _WorkspaceMoreActionWrapper(e, workspace))
          .toList(),
      buildChild: (controller) {
        return FlowyButton(
          useIntrinsicWidth: true,
          text: const FlowySvg(
            FlowySvgs.three_dots_vertical_s,
          ),
          onTap: () {
            controller.show();
          },
        );
      },
      onSelected: (action, controller) async {
        switch (action.inner) {
          case WorkspaceMoreAction.delete:
            break;
          case WorkspaceMoreAction.rename:
            break;
        }
        controller.close();
      },
    );
  }
}

class _WorkspaceMoreActionWrapper extends ActionCell {
  _WorkspaceMoreActionWrapper(this.inner, this.workspace);

  final WorkspaceMoreAction inner;
  final UserWorkspacePB workspace;

  @override
  String get name {
    switch (inner) {
      case WorkspaceMoreAction.delete:
        return LocaleKeys.button_delete.tr();
      case WorkspaceMoreAction.rename:
        return LocaleKeys.button_rename.tr();
    }
  }
}
