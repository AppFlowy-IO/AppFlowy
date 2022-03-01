import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class WorkspaceService {
  Future<Either<App, FlowyError>> createApp({required String workspaceId, required String name, required String desc}) {
    final request = CreateAppPayload.create()
      ..name = name
      ..workspaceId = workspaceId
      ..desc = desc;
    return FolderEventCreateApp(request).send();
  }

  Future<Either<Workspace, FlowyError>> getWorkspace({required String workspaceId}) {
    final request = WorkspaceId.create()..value = workspaceId;
    return FolderEventReadWorkspaces(request).send().then((result) {
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

  Future<Either<List<App>, FlowyError>> getApps({required String workspaceId}) {
    final request = WorkspaceId.create()..value = workspaceId;
    return FolderEventReadWorkspaceApps(request).send().then((result) {
      return result.fold(
        (apps) => left(apps.items),
        (error) => right(error),
      );
    });
  }
}
