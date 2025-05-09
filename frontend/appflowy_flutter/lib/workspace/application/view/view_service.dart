import 'dart:async';

import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_bloc.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';

class ViewBackendService {
  static Future<FlowyResult<ViewPB, FlowyError>> createView({
    /// The [layoutType] is the type of the view.
    required ViewLayoutPB layoutType,

    /// The [parentViewId] is the parent view id.
    required String parentViewId,

    /// The [name] is the name of the view.
    required String name,

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
    ViewSectionPB? section,
    final String? viewId,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = parentViewId
      ..name = name
      ..layout = layoutType
      ..setAsCurrent = openAfterCreate
      ..initialData = initialDataBytes ?? [];

    if (ext.isNotEmpty) {
      payload.meta.addAll(ext);
    }

    if (index != null) {
      payload.index = index;
    }

    if (section != null) {
      payload.section = section;
    }

    if (viewId != null) {
      payload.viewId = viewId;
    }

    return FolderEventCreateView(payload).send();
  }

  /// The orphan view is meant to be a view that is not attached to any parent view. By default, this
  /// view will not be shown in the view list unless it is attached to a parent view that is shown in
  /// the view list.
  static Future<FlowyResult<ViewPB, FlowyError>> createOrphanView({
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
      ..layout = layoutType
      ..initialData = initialDataBytes ?? [];

    return FolderEventCreateOrphanView(payload).send();
  }

  static Future<FlowyResult<ViewPB, FlowyError>> createDatabaseLinkedView({
    required String parentViewId,
    required String databaseId,
    required ViewLayoutPB layoutType,
    required String name,
  }) {
    return createView(
      layoutType: layoutType,
      parentViewId: parentViewId,
      name: name,
      ext: {'database_id': databaseId},
    );
  }

  /// Returns a list of views that are the children of the given [viewId].
  static Future<FlowyResult<List<ViewPB>, FlowyError>> getChildViews({
    required String viewId,
  }) {
    if (viewId.isEmpty) {
      return Future.value(
        FlowyResult<List<ViewPB>, FlowyError>.success(<ViewPB>[]),
      );
    }

    final payload = ViewIdPB.create()..value = viewId;

    return FolderEventGetView(payload).send().then((result) {
      return result.fold(
        (view) => FlowyResult.success(view.childViews),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  static Future<FlowyResult<void, FlowyError>> deleteView({
    required String viewId,
  }) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventDeleteView(request).send();
  }

  static Future<FlowyResult<void, FlowyError>> deleteViews({
    required List<String> viewIds,
  }) {
    final request = RepeatedViewIdPB.create()..items.addAll(viewIds);
    return FolderEventDeleteView(request).send();
  }

  static Future<FlowyResult<ViewPB, FlowyError>> duplicate({
    required ViewPB view,
    required bool openAfterDuplicate,
    // should include children views
    required bool includeChildren,
    String? parentViewId,
    String? suffix,
    required bool syncAfterDuplicate,
  }) {
    final payload = DuplicateViewPayloadPB.create()
      ..viewId = view.id
      ..openAfterDuplicate = openAfterDuplicate
      ..includeChildren = includeChildren
      ..syncAfterCreate = syncAfterDuplicate;

    if (parentViewId != null) {
      payload.parentViewId = parentViewId;
    }

    if (suffix != null) {
      payload.suffix = suffix;
    }

    return FolderEventDuplicateView(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> favorite({
    required String viewId,
  }) {
    final request = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventToggleFavorite(request).send();
  }

  static Future<FlowyResult<ViewPB, FlowyError>> updateView({
    required String viewId,
    String? name,
    bool? isFavorite,
    String? extra,
  }) {
    final payload = UpdateViewPayloadPB.create()..viewId = viewId;

    if (name != null) {
      payload.name = name;
    }

    if (isFavorite != null) {
      payload.isFavorite = isFavorite;
    }

    if (extra != null) {
      payload.extra = extra;
    }

    return FolderEventUpdateView(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> updateViewIcon({
    required ViewPB view,
    required EmojiIconData viewIcon,
  }) {
    final viewId = view.id;
    final oldIcon = view.icon.toEmojiIconData();
    final icon = viewIcon.toViewIcon();
    final payload = UpdateViewIconPayloadPB.create()
      ..viewId = viewId
      ..icon = icon;
    if (oldIcon.type == FlowyIconType.custom &&
        viewIcon.emoji != oldIcon.emoji) {
      DocumentEventDeleteFile(
        DeleteFilePB(url: oldIcon.emoji),
      ).send().onFailure((e) {
        Log.error(
          'updateViewIcon error while deleting :${oldIcon.emoji}, error: ${e.msg}, ${e.code}',
        );
      });
    }
    return FolderEventUpdateViewIcon(payload).send();
  }

  // deprecated
  static Future<FlowyResult<void, FlowyError>> moveView({
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
  static Future<FlowyResult<void, FlowyError>> moveViewV2({
    required String viewId,
    required String newParentId,
    required String? prevViewId,
    ViewSectionPB? fromSection,
    ViewSectionPB? toSection,
  }) {
    final payload = MoveNestedViewPayloadPB(
      viewId: viewId,
      newParentId: newParentId,
      prevViewId: prevViewId,
      fromSection: fromSection,
      toSection: toSection,
    );

    return FolderEventMoveNestedView(payload).send();
  }

  /// Fetches a flattened list of all Views.
  ///
  /// Views do not contain their children in this list, as they all exist
  /// in the same level in this version.
  ///
  static Future<FlowyResult<RepeatedViewPB, FlowyError>> getAllViews() async {
    return FolderEventGetAllViews().send();
  }

  static Future<FlowyResult<ViewPB, FlowyError>> getView(
    String viewId,
  ) async {
    if (viewId.isEmpty) {
      Log.error('ViewId is empty');
    }
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventGetView(payload).send();
  }

  static Future<MentionPageStatus> getMentionPageStatus(String pageId) async {
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.toNullable(),
    );

    // found the page
    if (view != null) {
      return (view, false, false);
    }

    // if the view is not found, try to fetch from trash
    final trashViews = await TrashService().readTrash();
    final trash = trashViews.fold(
      (l) => l.items.firstWhereOrNull((element) => element.id == pageId),
      (r) => null,
    );
    if (trash != null) {
      final trashView = ViewPB()
        ..id = trash.id
        ..name = trash.name;
      return (trashView, true, false);
    }

    // the page was deleted
    return (null, false, true);
  }

  static Future<FlowyResult<RepeatedViewPB, FlowyError>> getViewAncestors(
    String viewId,
  ) async {
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventGetViewAncestors(payload).send();
  }

  Future<FlowyResult<ViewPB, FlowyError>> getChildView({
    required String parentViewId,
    required String childViewId,
  }) async {
    final payload = ViewIdPB.create()..value = parentViewId;
    return FolderEventGetView(payload).send().then((result) {
      return result.fold(
        (app) => FlowyResult.success(
          app.childViews.firstWhere((e) => e.id == childViewId),
        ),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  static Future<FlowyResult<void, FlowyError>> updateViewsVisibility(
    List<ViewPB> views,
    bool isPublic,
  ) async {
    final payload = UpdateViewVisibilityStatusPayloadPB(
      viewIds: views.map((e) => e.id).toList(),
      isPublic: isPublic,
    );
    return FolderEventUpdateViewVisibilityStatus(payload).send();
  }

  static Future<FlowyResult<PublishInfoResponsePB, FlowyError>> getPublishInfo(
    ViewPB view,
  ) async {
    final payload = ViewIdPB()..value = view.id;
    return FolderEventGetPublishInfo(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> publish(
    ViewPB view, {
    String? name,
    List<String>? selectedViewIds,
  }) async {
    final payload = PublishViewParamsPB()..viewId = view.id;

    if (name != null) {
      payload.publishName = name;
    }

    if (selectedViewIds != null && selectedViewIds.isNotEmpty) {
      payload.selectedViewIds = RepeatedViewIdPB(items: selectedViewIds);
    }

    return FolderEventPublishView(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> unpublish(
    ViewPB view,
  ) async {
    final payload = UnpublishViewsPayloadPB(viewIds: [view.id]);
    return FolderEventUnpublishViews(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> setPublishNameSpace(
    String name,
  ) async {
    final payload = SetPublishNamespacePayloadPB()..newNamespace = name;
    return FolderEventSetPublishNamespace(payload).send();
  }

  static Future<FlowyResult<PublishNamespacePB, FlowyError>>
      getPublishNameSpace() async {
    return FolderEventGetPublishNamespace().send();
  }

  static Future<List<ViewPB>> getAllChildViews(ViewPB view) async {
    final views = <ViewPB>[];

    final childViews =
        await ViewBackendService.getChildViews(viewId: view.id).fold(
      (s) => s,
      (f) => [],
    );

    for (final child in childViews) {
      // filter the view itself
      if (child.id == view.id) {
        continue;
      }
      views.add(child);
      views.addAll(await getAllChildViews(child));
    }

    return views;
  }

  static Future<(bool, List<ViewPB>)> containPublishedPage(ViewPB view) async {
    final childViews = await ViewBackendService.getAllChildViews(view);
    final views = [view, ...childViews];
    final List<ViewPB> publishedPages = [];

    for (final view in views) {
      final publishInfo = await ViewBackendService.getPublishInfo(view);
      if (publishInfo.isSuccess) {
        publishedPages.add(view);
      }
    }

    return (publishedPages.isNotEmpty, publishedPages);
  }

  static Future<FlowyResult<void, FlowyError>> lockView(String viewId) async {
    final payload = ViewIdPB()..value = viewId;
    return FolderEventLockView(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> unlockView(String viewId) async {
    final payload = ViewIdPB()..value = viewId;
    return FolderEventUnlockView(payload).send();
  }
}
