import 'dart:math';

import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceIcon extends StatefulWidget {
  const WorkspaceIcon({
    super.key,
    required this.enableEdit,
    required this.iconSize,
    required this.workspace,
  });

  final UserWorkspacePB workspace;
  final double iconSize;
  final bool enableEdit;

  @override
  State<WorkspaceIcon> createState() => _WorkspaceIconState();
}

class _WorkspaceIconState extends State<WorkspaceIcon> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    Widget child = widget.workspace.icon.isNotEmpty
        ? Container(
            width: widget.iconSize,
            alignment: Alignment.center,
            child: FlowyText(
              widget.workspace.icon,
              fontSize: widget.iconSize,
            ),
          )
        : Container(
            alignment: Alignment.center,
            width: widget.iconSize,
            height: max(widget.iconSize, 26),
            decoration: BoxDecoration(
              color: ColorGenerator(widget.workspace.name).toColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FlowyText(
              widget.workspace.name.isEmpty
                  ? ''
                  : widget.workspace.name.substring(0, 1),
              fontSize: 16,
              color: Colors.black,
            ),
          );
    if (widget.enableEdit) {
      child = AppFlowyPopover(
        offset: const Offset(0, 8),
        controller: controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: BoxConstraints.loose(const Size(360, 380)),
        clickHandler: PopoverClickHandler.gestureDetector,
        popupBuilder: (BuildContext popoverContext) {
          return FlowyIconPicker(
            onSelected: (result) {
              context.read<UserWorkspaceBloc>().add(
                    UserWorkspaceEvent.updateWorkspaceIcon(
                      widget.workspace.workspaceId,
                      result.emoji,
                    ),
                  );
              controller.close();
            },
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        ),
      );
    }
    return child;
  }
}
