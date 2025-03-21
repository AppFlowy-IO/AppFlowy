import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class WorkspaceHttpService {
  WorkspaceHttpService({required this.workspaceId});

  final String workspaceId;

  /// Get the folder of the workspace.
  ///
  /// [rootViewId] is the id of the root view you want to get.
  /// [depth] controls the depth of the returned folder.
  Future<FlowyResult<FolderViewPB, FlowyError>> getWorkspaceFolder({
    String? rootViewId,
    int depth = 10,
  }) {
    final payload = GetWorkspaceFolderViewPB.create()
      ..workspaceId = workspaceId
      ..depth = depth;

    if (rootViewId != null) {
      payload.rootViewId = rootViewId;
    }

    return FolderEventGetWorkspaceFolder(payload).send();
  }
}
