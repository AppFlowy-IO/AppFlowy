import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class WorkspaceIcon extends StatelessWidget {
  const WorkspaceIcon({
    super.key,
    required this.workspace,
  });

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    // TODO(Lucas): support icon later
    return Container(
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
    );
  }
}
