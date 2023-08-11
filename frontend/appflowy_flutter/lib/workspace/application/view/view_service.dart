import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';

class ViewBackendService {
  static Future<Either<ViewPB, FlowyError>> createView({
    /// The [layoutType] is the type of the view.
    required ViewLayoutPB layoutType,

    /// The [parentViewId] is the parent view id.
    required String parentViewId,

    /// The [name] is the name of the view.
    required String name,
    String? desc,

    /// The default value of [openAfterCreate] is false, meaning the view will
    /// not be opened nor set as the current view. However, if set to true, the
    /// view will be opened and set as the current view. Upon relaunching the
    /// app, this view will be opened
    bool openAfterCreate = false,

    /// The initial data should be a JSON that represent the DocumentDataPB.
    /// Currently, only support create document with initial data.
    List<int>? initialDataBytes,

    /// The [ext] is used to pass through the custom configuration
    /// to the backend.
    /// Linking the view to the existing database, it needs to pass
    /// the database id. For example: "database_id": "xxx"
    ///
    Map<String, String> ext = const {},

    /// The [index] is the index of the view in the parent view.
    /// If the index is null, the view will be added to the end of the list.
    int? index,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = parentViewId
      ..name = name
      ..desc = desc ?? ""
      ..layout = layoutType
      ..setAsCurrent = openAfterCreate
      ..initialData = initialDataBytes ?? [];

    if (ext.isNotEmpty) {
      payload.meta.addAll(ext);
    }

    if (desc != null) {
      payload.desc = desc;
    }

    if (index != null) {
      payload.index = index;
    }

    return FolderEventCreateView(payload).send();
  }

  /// The orphan view is meant to be a view that is not attached to any parent view. By default, this
  /// view will not be shown in the view list unless it is attached to a parent view that is shown in
  /// the view list.
  static Future<Either<ViewPB, FlowyError>> createOrphanView({
    required String viewId,
    required ViewLayoutPB layoutType,
    required String name,
    String? desc,

    /// The initial data should be a JSON that represent the DocumentDataPB.
    /// Currently, only support create document with initial data.
    List<int>? initialDataBytes,
  }) {
    final payload = CreateOrphanViewPayloadPB.create()
      ..viewId = viewId
      ..name = name
      ..desc = desc ?? ""
      ..layout = layoutType
      ..initialData = initialDataBytes ?? [];

    return FolderEventCreateOrphanView(payload).send();
  }

  static Future<Either<ViewPB, FlowyError>> createDatabaseLinkedView({
    required String parentViewId,
    required String databaseId,
    required ViewLayoutPB layoutType,
    required String name,
  }) {
    return ViewBackendService.createView(
      layoutType: layoutType,
      parentViewId: parentViewId,
      name: name,
      openAfterCreate: false,
      ext: {
        'database_id': databaseId,
      },
    );
  }

  /// Returns a list of views that are the children of the given [viewId].
  static Future<Either<List<ViewPB>, FlowyError>> getChildViews({
    required String viewId,
  }) {
    final payload = ViewIdPB.create()..value = viewId;

    return FolderEventReadView(payload).send().then((result) {
      return result.fold(
        (view) => left(view.childViews),
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

  static Future<Either<Unit, FlowyError>> favorite({required String viewId}) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventToggleFavorite(request).send();
  }

  static Future<Either<ViewPB, FlowyError>> updateView({
    required String viewId,
    String? name,
    bool? isFavorite,
  }) {
    final payload = UpdateViewPayloadPB.create()..viewId = viewId;

    if (name != null) {
      payload.name = name;
    }

    if (isFavorite != null) {
      payload.isFavorite = isFavorite;
    }
    return FolderEventUpdateView(payload).send();
  }

  // deprecated
  static Future<Either<Unit, FlowyError>> moveView({
    required String viewId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveViewPayloadPB.create()
      ..viewId = viewId
      ..from = fromIndex
      ..to = toIndex;

    return FolderEventMoveView(payload).send();
  }

  /// Move the view to the new parent view.
  ///
  /// supports nested view
  /// if the [prevViewId] is null, the view will be moved to the beginning of the list
  static Future<Either<Unit, FlowyError>> moveViewV2({
    required String viewId,
    required String newParentId,
    required String? prevViewId,
  }) {
    final payload = MoveNestedViewPayloadPB(
      viewId: viewId,
      newParentId: newParentId,
      prevViewId: prevViewId,
    );

    return FolderEventMoveNestedView(payload).send();
  }

  Future<List<ViewPB>> fetchViewsWithLayoutType(
    ViewLayoutPB? layoutType,
  ) async {
    final views = await fetchViews();
    if (layoutType == null) {
      return views;
    }
    return views
        .where(
          (element) => layoutType == element.layout,
        )
        .toList();
  }

  Future<List<ViewPB>> fetchViews() async {
    final result = <ViewPB>[];
    return FolderEventGetCurrentWorkspace().send().then((value) async {
      final workspaces = value.getLeftOrNull<WorkspaceSettingPB>();
      if (workspaces != null) {
        final views = workspaces.workspace.views;
        for (final view in views) {
          result.add(view);
          final childViews = await getAllViews(view);
          result.addAll(childViews);
        }
      }
      return result;
    });
  }

  Future<List<ViewPB>> getAllViews(ViewPB view) async {
    final result = <ViewPB>[];
    final childViews = await getChildViews(viewId: view.id).then(
      (value) => value.getLeftOrNull<List<ViewPB>>()?.toList(),
    );
    if (childViews != null && childViews.isNotEmpty) {
      result.addAll(childViews);
      final views = await Future.wait(
        childViews.map((e) async => await getAllViews(e)),
      );
      result.addAll(views.expand((element) => element));
    }
    return result;
  }

  static Future<Either<ViewPB, FlowyError>> getView(
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
