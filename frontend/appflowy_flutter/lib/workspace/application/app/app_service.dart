import 'dart:async';
import 'dart:convert';

import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class AppBackendService {
  Future<Either<AppPB, FlowyError>> readApp({required final String appId}) {
    final payload = AppIdPB.create()..value = appId;

    return FolderEventReadApp(payload).send();
  }

  Future<Either<ViewPB, FlowyError>> createView({
    required final String appId,
    required final String name,
    final String? desc,
    required final ViewLayoutTypePB layoutType,

    /// The initial data should be the JSON of the document.
    /// Currently, only support create document with initial data.
    ///
    /// The initial data must be follow this format as shown below.
    ///  {"document":{"type":"editor","children":[]}}
    final String? initialData,

    /// The [ext] is used to pass through the custom configuration
    /// to the backend.
    /// Linking the view to the existing database, it needs to pass
    /// the database id. For example: "database_id": "xxx"
    ///
    final Map<String, String> ext = const {},
  }) {
    final payload = CreateViewPayloadPB.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc ?? ""
      ..layout = layoutType
      ..initialData = utf8.encode(
        initialData ?? "",
      );

    if (ext.isNotEmpty) {
      payload.ext.addAll(ext);
    }

    return FolderEventCreateView(payload).send();
  }

  Future<Either<List<ViewPB>, FlowyError>> getViews({
    required final String appId,
  }) {
    final payload = AppIdPB.create()..value = appId;

    return FolderEventReadApp(payload).send().then((final result) {
      return result.fold(
        (final app) => left(app.belongings.items),
        (final error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> delete({required final String appId}) {
    final request = AppIdPB.create()..value = appId;
    return FolderEventDeleteApp(request).send();
  }

  Future<Either<Unit, FlowyError>> deleteView({required final String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> updateApp({
    required final String appId,
    final String? name,
  }) {
    final UpdateAppPayloadPB payload = UpdateAppPayloadPB.create()
      ..appId = appId;

    if (name != null) {
      payload.name = name;
    }
    return FolderEventUpdateApp(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveView({
    required final String viewId,
    required final int fromIndex,
    required final int toIndex,
  }) {
    final payload = MoveFolderItemPayloadPB.create()
      ..itemId = viewId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveView;

    return FolderEventMoveItem(payload).send();
  }

  Future<List<Tuple2<AppPB, List<ViewPB>>>> fetchViews(
    final ViewLayoutTypePB layoutType,
  ) async {
    final result = <Tuple2<AppPB, List<ViewPB>>>[];
    return FolderEventReadCurrentWorkspace().send().then((final value) async {
      final workspaces = value.getLeftOrNull<WorkspaceSettingPB>();
      if (workspaces != null) {
        final apps = workspaces.workspace.apps.items;
        for (final app in apps) {
          final views = await getViews(appId: app.id).then(
            (final value) => value
                .getLeftOrNull<List<ViewPB>>()
                ?.where((final e) => e.layout == layoutType)
                .toList(),
          );
          if (views != null && views.isNotEmpty) {
            result.add(Tuple2(app, views));
          }
        }
      }
      return result;
    });
  }

  Future<Either<ViewPB, FlowyError>> getView(
    final String appID,
    final String viewID,
  ) async {
    final payload = AppIdPB.create()..value = appID;
    return FolderEventReadApp(payload).send().then((final result) {
      return result.fold(
        (final app) => left(
          app.belongings.items.firstWhere((final e) => e.id == viewID),
        ),
        (final error) => right(error),
      );
    });
  }
}

extension AppFlowy on Either {
  T? getLeftOrNull<T>() {
    if (isLeft()) {
      final result = fold<T?>((final l) => l, (final r) => null);
      return result;
    }
    return null;
  }
}
