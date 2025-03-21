import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';

class PageHttpService {
  PageHttpService({required this.workspaceId});

  final String workspaceId;

  /// Unpublish the space in the workspace.
  ///
  /// [spaceView] is the space view you want to unpublish.
  Future<FlowyResult<void, FlowyError>> unpublishSpace({
    required FolderViewPB spaceView,
  }) {
    // get all the published views in the space
    final publishedPages = spaceView.publishedPages;

    final payload = UnpublishViewsPayloadPB.create()
      ..viewIds.addAll(publishedPages.map((e) => e.viewId));
    return FolderEventUnpublishViews(payload).send();
  }

  /// Create a page in the workspace.
  ///
  /// [parentViewId] is the id of the parent view.
  /// [name] is the name of the page.
  /// [layout] is the layout of the page.
  Future<FlowyResult<void, FlowyError>> createPage({
    required String parentViewId,
    required String name,
    required ViewLayoutPB layout,
  }) {
    final request = CreatePagePayloadPB(
      workspaceId: workspaceId,
      parentViewId: parentViewId,
      name: name,
      layout: layout,
    );
    return FolderEventCreatePage(request).send();
  }

  /// Update the page name in the workspace.
  ///
  /// [page] is the page you want to update.
  /// [name] is the name of the page.
  Future<FlowyResult<void, FlowyError>> updatePageName({
    required FolderViewPB page,
    required String name,
  }) {
    final payload = UpdatePagePayloadPB(
      workspaceId: workspaceId,
      viewId: page.viewId,
      name: name,
      icon: page.icon,
      isLocked: page.isLocked,
    );
    return FolderEventUpdatePage(payload).send();
  }

  /// Update the page icon in the workspace.
  ///
  /// [page] is the page you want to update.
  /// [icon] is the icon of the page.
  Future<FlowyResult<void, FlowyError>> updatePageIcon({
    required FolderViewPB page,
    ViewIconPB? icon,
    String? iconColor,
  }) {
    final payload = UpdatePagePayloadPB(
      workspaceId: workspaceId,
      viewId: page.viewId,
      icon: icon,
      name: page.name,
      isLocked: page.isLocked,
    );
    return FolderEventUpdatePage(payload).send();
  }

  /// Unpublish the page in the workspace.
  ///
  /// [pageView] is the page view you want to unpublish.
  Future<FlowyResult<void, FlowyError>> unpublishPage({
    required FolderViewPB page,
  }) {
    final publishedPages = page.publishedPages;
    final payload = UnpublishViewsPayloadPB.create()
      ..viewIds.addAll(publishedPages.map((e) => e.viewId));
    return FolderEventUnpublishViews(payload).send();
  }

  /// Move the page in the workspace.
  ///
  /// [page] is the page you want to move.
  /// [newParentViewId] is the id of the new parent view.
  /// [prevViewId] is the id of the previous view of insert position.
  Future<FlowyResult<void, FlowyError>> movePage({
    required FolderViewPB page,
    required String newParentViewId,
    String? prevViewId,
  }) {
    final payload = MovePagePayloadPB(
      workspaceId: workspaceId,
      viewId: page.viewId,
      newParentViewId: newParentViewId,
      prevViewId: prevViewId,
    );
    return FolderEventMovePage(payload).send();
  }

  /// Duplicate the page in the workspace.
  ///
  /// [page] is the page you want to duplicate.
  Future<FlowyResult<void, FlowyError>> duplicatePage({
    required FolderViewPB page,
    String? suffix,
  }) {
    final payload = DuplicatePagePayloadPB(
      workspaceId: workspaceId,
      viewId: page.viewId,
      suffix: suffix ?? ' (${LocaleKeys.menuAppHeader_pageNameSuffix.tr()})',
    );
    return FolderEventDuplicatePage(payload).send();
  }

  /// Delete the page in the workspace.
  ///
  /// [page] is the page you want to delete.
  Future<FlowyResult<void, FlowyError>> deletePage({
    required FolderViewPB page,
  }) {
    final payload = MovePageToTrashPayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = page.viewId;
    return FolderEventMovePageToTrash(payload).send();
  }
}
