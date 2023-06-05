import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart'
    show MoveFolderItemPayloadPB, MoveFolderItemType;
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';

import 'package:appflowy/generated/locale_keys.g.dart';

class WorkspaceService {
  final String workspaceId;
  WorkspaceService({
    required this.workspaceId,
  });
  Future<Either<AppPB, FlowyError>> createApp({
    required final String name,
    final String? desc,
  }) {
    final payload = CreateAppPayloadPB.create()
      ..name = name
      ..workspaceId = workspaceId
      ..desc = desc ?? "";
    return FolderEventCreateApp(payload).send();
  }

  Future<Either<WorkspacePB, FlowyError>> getWorkspace() {
    final payload = WorkspaceIdPB.create()..value = workspaceId;
    return FolderEventReadWorkspaces(payload).send().then((final result) {
      return result.fold(
        (final workspaces) {
          assert(workspaces.items.length == 1);

          if (workspaces.items.isEmpty) {
            return right(
              FlowyError.create()
                ..msg = LocaleKeys.workspace_notFoundError.tr(),
            );
          } else {
            return left(workspaces.items[0]);
          }
        },
        (final error) => right(error),
      );
    });
  }

  Future<Either<List<AppPB>, FlowyError>> getApps() {
    final payload = WorkspaceIdPB.create()..value = workspaceId;
    return FolderEventReadWorkspaceApps(payload).send().then((final result) {
      return result.fold(
        (final apps) => left(apps.items),
        (final error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> moveApp({
    required final String appId,
    required final int fromIndex,
    required final int toIndex,
  }) {
    final payload = MoveFolderItemPayloadPB.create()
      ..itemId = appId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveApp;

    return FolderEventMoveItem(payload).send();
  }
}
