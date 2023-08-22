import 'package:appflowy/workspace/application/workspace/workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void popToWorkspace(BuildContext context, WorkspacePB workspace) {
  context.read<WorkspaceBloc>().add(WorkspaceEvent.openWorkspace(workspace));

  Navigator.of(context).pop(workspace.id);
}
