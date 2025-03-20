import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';

class WorkspaceHttpService {
  WorkspaceHttpService({required this.workspaceId});

  final String workspaceId;

  /// Get the folder of the workspace.
  ///
  /// [rootViewId] is the id of the root view you want to get.
  /// [depth] controls the depth of the returned folder.
  Future<FlowyResult<FolderViewPB, FlowyError>> getWorkspaceFolder({
    String? rootViewId,
    int depth = 10,
  }) {
    final payload = GetWorkspaceFolderViewPB.create()
      ..workspaceId = workspaceId
      ..depth = depth;

    if (rootViewId != null) {
      payload.rootViewId = rootViewId;
    }

    return FolderEventGetWorkspaceFolder(payload).send();
  }
}

class SpaceHttpService {
  SpaceHttpService({required this.workspaceId});

  final String workspaceId;

  /// Get the space of the workspace.
  ///
  /// [rootViewId] is the id of the root view you want to get.
  /// [depth] controls the depth of the returned folder.
  Future<FlowyResult<List<FolderViewPB>, FlowyError>> getSpaceList({
    String? rootViewId,
    int depth = 10,
  }) {
    final payload = GetWorkspaceFolderViewPB.create()
      ..workspaceId = workspaceId
      ..depth = depth;

    if (rootViewId != null) {
      payload.rootViewId = rootViewId;
    }

    return FolderEventGetWorkspaceFolder(payload).send().then((response) {
      return response.fold(
        (folderView) {
          return FlowyResult.success(
            folderView.children.where((e) => e.isSpace).toList(),
          );
        },
        (error) {
          return FlowyResult.failure(error);
        },
      );
    });
  }

  /// Create a space in the workspace.
  ///
  /// [name] is the name of the space.
  /// [icon] is the icon of the space.
  /// [iconColor] is the color of the icon.
  /// [permission] is the permission of the space.
  Future<FlowyResult<void, FlowyError>> createSpace({
    required String name,
    required String icon,
    required String iconColor,
    required SpacePermission permission,
  }) {
    final payload = CreateSpacePayloadPB.create()
      ..workspaceId = workspaceId
      ..name = name
      ..spacePermission = permission.toSpacePermissionPB()
      ..spaceIcon = icon
      ..spaceIconColor = iconColor;

    return FolderEventCreateSpace(payload).send();
  }

  /// Update the space name in the workspace.
  ///
  /// [name] is the name of the space.
  Future<FlowyResult<void, FlowyError>> updateSpaceName({
    required FolderViewPB space,
    required String name,
  }) {
    final payload = UpdateSpacePayloadPB.create()
      ..workspaceId = workspaceId
      ..spaceId = space.viewId
      ..name = name
      ..spacePermission = space.spacePermissionPB;

    final spaceIcon = space.spaceIcon;

    if (spaceIcon != null) {
      payload.spaceIcon = spaceIcon;
    }

    final spaceIconColor = space.spaceIconColor;
    if (spaceIconColor != null) {
      payload.spaceIconColor = spaceIconColor;
    }

    return FolderEventUpdateSpace(payload).send();
  }

  /// Duplicate the space in the workspace.
  ///
  /// [space] is the space you want to duplicate.
  Future<FlowyResult<void, FlowyError>> duplicateSpace({
    required FolderViewPB space,
  }) {
    final payload = DuplicatePagePayloadPB(
      workspaceId: workspaceId,
      viewId: space.viewId,
      suffix: ' (${LocaleKeys.menuAppHeader_pageNameSuffix.tr()})',
    );
    return FolderEventDuplicatePage(payload).send();
  }

  /// Update the space in the workspace.
  ///
  /// [space] is the space you want to update.
  /// [name] is the name of the space.
  /// [icon] is the icon of the space.
  /// [iconColor] is the color of the icon.
  /// [permission] is the permission of the space.
  Future<FlowyResult<void, FlowyError>> updateSpace({
    required FolderViewPB space,
    String? name,
    String? icon,
    String? iconColor,
    SpacePermission? permission,
  }) {
    final payload = UpdateSpacePayloadPB.create()
      ..workspaceId = workspaceId
      ..spaceId = space.viewId
      ..name = name ?? space.name
      ..spacePermission =
          permission?.toSpacePermissionPB() ?? space.spacePermissionPB
      ..spaceIcon = icon ?? space.spaceIcon ?? ''
      ..spaceIconColor = iconColor ?? space.spaceIconColor ?? '';

    return FolderEventUpdateSpace(payload).send();
  }

  /// Update the space icon in the workspace.
  ///
  /// [spaceId] is the id of the space you want to update.
  /// [icon] is the icon of the space.
  /// [iconColor] is the color of the icon.
  Future<FlowyResult<void, FlowyError>> updateSpaceIcon({
    required FolderViewPB space,
    String? icon,
    String? iconColor,
  }) {
    assert(icon != null || iconColor != null);

    final payload = UpdateSpacePayloadPB.create()
      ..workspaceId = workspaceId
      ..name = space.name
      ..spaceId = space.viewId
      ..spacePermission = space.spacePermissionPB;

    icon ??= space.spaceIcon;
    iconColor ??= space.spaceIconColor;

    if (icon != null) {
      payload.spaceIcon = icon;
    }

    if (iconColor != null) {
      payload.spaceIconColor = iconColor;
    }

    return FolderEventUpdateSpace(payload).send();
  }

  /// Delete the space in the workspace.
  ///
  /// [space] is the space you want to delete.
  Future<FlowyResult<void, FlowyError>> deleteSpace({
    required FolderViewPB space,
  }) {
    final payload = MovePageToTrashPayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = space.viewId;
    return FolderEventMovePageToTrash(payload).send();
  }
}

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
