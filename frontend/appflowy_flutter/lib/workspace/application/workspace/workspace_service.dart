import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class WorkspaceService {
  WorkspaceService({required this.workspaceId});

  final String workspaceId;

  Future<FlowyResult<ViewPB, FlowyError>> createView({
    required String name,
    String? desc,
    int? index,
    required ViewSectionPB viewSection,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = workspaceId
      ..name = name
      // only allow document layout for the top-level views
      ..layout = ViewLayoutPB.Document
      ..section = viewSection;

    if (desc != null) {
      payload.desc = desc;
    }

    if (index != null) {
      payload.index = index;
    }

    return FolderEventCreateView(payload).send();
  }

  Future<FlowyResult<WorkspacePB, FlowyError>> getWorkspace() {
    return FolderEventReadCurrentWorkspace().send();
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPublicViews() {
    final payload = GetWorkspaceViewPB.create()..value = workspaceId;
    return FolderEventReadWorkspaceViews(payload).send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPrivateViews() {
    return FolderEventReadPrivateViews().send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> moveApp({
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
