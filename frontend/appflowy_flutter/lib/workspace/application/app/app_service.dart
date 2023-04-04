import 'dart:async';
import 'dart:convert';

import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';

class AppBackendService {
  Future<Either<ViewPB, FlowyError>> createView({
    required String appId,
    required String name,
    String? desc,
    required ViewLayoutTypePB layoutType,

    /// The initial data should be the JSON of the document.
    /// Currently, only support create document with initial data.
    ///
    /// The initial data must be follow this format as shown below.
    ///  {"document":{"type":"editor","children":[]}}
    String? initialData,

    /// The [ext] is used to pass through the custom configuration
    /// to the backend.
    /// Linking the view to the existing database, it needs to pass
    /// the database id. For example: "database_id": "xxx"
    ///
    Map<String, String> ext = const {},
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

  Future<Either<List<ViewPB>, FlowyError>> getViews({required String viewId}) {
    final payload = ViewIdPB.create()..value = viewId;

    return FolderEventReadView(payload).send().then((result) {
      return result.fold(
        (app) => left(app.belongings),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> delete({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<Unit, FlowyError>> deleteView({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  Future<Either<ViewPB, FlowyError>> updateApp(
      {required String appId, String? name}) {
    var payload = UpdateViewPayloadPB.create()..viewId = appId;

    if (name != null) {
      payload.name = name;
    }
    return FolderEventUpdateView(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveView({
    required String viewId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveFolderItemPayloadPB.create()
      ..itemId = viewId
      ..from = fromIndex
      ..to = toIndex
      ..ty = MoveFolderItemType.MoveView;

    return FolderEventMoveItem(payload).send();
  }

  Future<List<Tuple2<ViewPB, List<ViewPB>>>> fetchViews(
      ViewLayoutTypePB layoutType) async {
    final result = <Tuple2<ViewPB, List<ViewPB>>>[];
    return FolderEventReadCurrentWorkspace().send().then((value) async {
      final workspaces = value.getLeftOrNull<WorkspaceSettingPB>();
      if (workspaces != null) {
        final views = workspaces.workspace.views;
        for (var view in views) {
          final childViews = await getViews(viewId: view.id).then(
            (value) => value
                .getLeftOrNull<List<ViewPB>>()
                ?.where((e) => e.layout == layoutType)
                .toList(),
          );
          if (childViews != null && childViews.isNotEmpty) {
            result.add(Tuple2(view, childViews));
          }
        }
      }
      return result;
    });
  }

  Future<Either<ViewPB, FlowyError>> getView(
    String viewID,
  ) async {
    final payload = ViewIdPB.create()..value = viewID;
    return FolderEventReadView(payload).send();
  }

  Future<Either<ViewPB, FlowyError>> getChildView(
    String viewID,
    String childViewID,
  ) async {
    final payload = ViewIdPB.create()..value = viewID;
    return FolderEventReadView(payload).send().then((result) {
      return result.fold(
        (app) => left(
          app.belongings.firstWhere((e) => e.id == childViewID),
        ),
        (error) => right(error),
      );
    });
  }
}

extension AppFlowy on Either {
  T? getLeftOrNull<T>() {
    if (isLeft()) {
      final result = fold<T?>((l) => l, (r) => null);
      return result;
    }
    return null;
  }
}
