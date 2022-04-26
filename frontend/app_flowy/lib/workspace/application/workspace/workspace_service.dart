import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart' show MoveFolderItemPayload, MoveFolderItemType;
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';

class WorkspaceService {
  final String workspaceId;
  WorkspaceService({
    required this.workspaceId,
  });
  Future<Either<App, FlowyError>> createApp({required String name, required String desc}) {
    final payload = CreateAppPayload.create()
      ..name = name
      ..workspaceId = workspaceId
      ..desc = desc;
    return FolderEventCreateApp(payload).send();
  }

  Future<Either<Workspace, FlowyError>> getWorkspace() {
    final payload = WorkspaceId.create()..value = workspaceId;
    return FolderEventReadWorkspaces(payload).send().then((result) {
      return result.fold(
        (workspaces) {
          assert(workspaces.items.length == 1);

          if (workspaces.items.isEmpty) {
            return right(FlowyError.create()..msg = LocaleKeys.workspace_notFoundError.tr());
          } else {
            return left(workspaces.items[0]);
          }
        },
        (error) => right(error),
      );
    });
  }

  Future<Either<List<App>, FlowyError>> getApps() {
    final payload = WorkspaceId.create()..value = workspaceId;
    return FolderEventReadWorkspaceApps(payload).send().then((result) {
      return result.fold(
        (apps) => left(apps.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> moveApp({
    required String appId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveFolderItemPayload.create()
      ..itemId = appId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveApp;

    return FolderEventMoveItem(payload).send();
  }
}
