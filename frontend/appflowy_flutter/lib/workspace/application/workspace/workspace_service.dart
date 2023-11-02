import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart'
    show CreateViewPayloadPB, MoveViewPayloadPB, ViewLayoutPB, ViewPB;
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';

class WorkspaceService {
  final String workspaceId;
  WorkspaceService({
    required this.workspaceId,
  });

  Future<Either<ViewPB, FlowyError>> createApp({
    required String name,
    String? desc,
    int? index,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = workspaceId
      ..name = name
      ..layout = ViewLayoutPB.Document;

    if (desc != null) {
      payload.desc = desc;
    }

    if (index != null) {
      payload.index = index;
    }

    return FolderEventCreateView(payload).send();
  }

  Future<Either<WorkspacePB, FlowyError>> getWorkspace() {
    return FolderEventReadCurrentWorkspace().send();
  }

  Future<Either<List<ViewPB>, FlowyError>> getViews() {
    final payload = WorkspaceIdPB.create()..value = workspaceId;
    return FolderEventReadWorkspaceViews(payload).send().then((result) {
      return result.fold(
        (views) => left(views.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> moveApp({
    required String appId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveViewPayloadPB.create()
      ..viewId = appId
      ..from = fromIndex
      ..to = toIndex;

    return FolderEventMoveView(payload).send();
  }
}
