import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';

class ViewBackendService {
  static Future<Either<ViewPB, FlowyError>> createView({
    required ViewLayoutPB layoutType,
    required String parentViewId,
    required String name,
    String? desc,

    /// The initial data should be a JSON that represent the DocumentDataPB.
    /// Currently, only support create document with initial data.
    List<int>? initialDataBytes,

    /// The [ext] is used to pass through the custom configuration
    /// to the backend.
    /// Linking the view to the existing database, it needs to pass
    /// the database id. For example: "database_id": "xxx"
    ///
    Map<String, String> ext = const {},
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = parentViewId
      ..name = name
      ..desc = desc ?? ""
      ..layout = layoutType
      ..initialData = initialDataBytes ?? [];

    if (ext.isNotEmpty) {
      payload.ext.addAll(ext);
    }

    return FolderEventCreateView(payload).send();
  }

  static Future<Either<ViewPB, FlowyError>> createDatabaseReferenceView({
    required String parentViewId,
    required String databaseId,
    required ViewLayoutPB layoutType,
    required String name,
  }) {
    return ViewBackendService.createView(
      layoutType: layoutType,
      parentViewId: parentViewId,
      name: name,
      ext: {
        'database_id': databaseId,
      },
    );
  }

  static Future<Either<List<ViewPB>, FlowyError>> getViews({
    required String viewId,
  }) {
    final payload = ViewIdPB.create()..value = viewId;

    return FolderEventReadView(payload).send().then((result) {
      return result.fold(
        (app) => left(app.childViews),
        (error) => right(error),
      );
    });
  }

  static Future<Either<Unit, FlowyError>> delete({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  static Future<Either<Unit, FlowyError>> deleteView({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  static Future<Either<Unit, FlowyError>> duplicate({required ViewPB view}) {
    return FolderEventDuplicateView(view).send();
  }

  static Future<Either<ViewPB, FlowyError>> updateView({
    required String viewId,
    String? name,
  }) {
    var payload = UpdateViewPayloadPB.create()..viewId = viewId;

    if (name != null) {
      payload.name = name;
    }
    return FolderEventUpdateView(payload).send();
  }

  static Future<Either<Unit, FlowyError>> moveView({
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

  Future<List<(ViewPB, List<ViewPB>)>> fetchViews(
    ViewLayoutPB layoutType,
  ) async {
    final result = <(ViewPB, List<ViewPB>)>[];
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
            result.add((view, childViews));
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

  Future<Either<ViewPB, FlowyError>> getChildView({
    required String parentViewId,
    required String childViewId,
  }) async {
    final payload = ViewIdPB.create()..value = parentViewId;
    return FolderEventReadView(payload).send().then((result) {
      return result.fold(
        (app) => left(
          app.childViews.firstWhere((e) => e.id == childViewId),
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
