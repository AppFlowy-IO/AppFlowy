import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceIcon extends StatelessWidget {
  const WorkspaceIcon({
    super.key,
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: const Offset(0, 8),
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(360, 380)),
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (BuildContext popoverContext) {
        return FlowyIconPicker(
          onSelected: (result) {
            context.read<UserWorkspaceBloc>().add(
                  UserWorkspaceEvent.updateWorkspaceIcon(
                    workspace.workspaceId,
                    result.emoji,
                  ),
                );
          },
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorGenerator.generateColorFromString(workspace.name),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FlowyText(
            workspace.name.isEmpty ? '' : workspace.name.substring(0, 1),
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
