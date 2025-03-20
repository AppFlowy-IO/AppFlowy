import 'dart:async';
import 'dart:convert';

import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class WorkspaceService {
  WorkspaceService({required this.workspaceId});

  final String workspaceId;

  Future<FlowyResult<ViewPB, FlowyError>> createView({
    required String name,
    required ViewSectionPB viewSection,
    int? index,
    ViewLayoutPB? layout,
    bool? setAsCurrent,
    String? viewId,
    String? extra,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = workspaceId
      ..name = name
      ..layout = layout ?? ViewLayoutPB.Document
      ..section = viewSection;

    if (index != null) {
      payload.index = index;
    }

    if (setAsCurrent != null) {
      payload.setAsCurrent = setAsCurrent;
    }

    if (viewId != null) {
      payload.viewId = viewId;
    }

    if (extra != null) {
      payload.extra = extra;
    }

    return FolderEventCreateView(payload).send();
  }

  Future<FlowyResult<WorkspacePB, FlowyError>> getWorkspace() {
    return FolderEventReadCurrentWorkspace().send();
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPublicViews() {
    final payload = GetWorkspaceViewPB.create()..value = workspaceId;
    return FolderEventReadWorkspaceViews(payload).send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPrivateViews() {
    final payload = GetWorkspaceViewPB.create()..value = workspaceId;
    return FolderEventReadPrivateViews(payload).send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> moveView({
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

  Future<FlowyResult<WorkspaceUsagePB, FlowyError>> getWorkspaceUsage() {
    final payload = UserWorkspaceIdPB(workspaceId: workspaceId);
    return UserEventGetWorkspaceUsage(payload).send();
  }

  Future<FlowyResult<BillingPortalPB, FlowyError>> getBillingPortal() {
    return UserEventGetBillingPortal().send();
  }

  /// Get all spaces in the workspace.
  Future<FlowyResult<List<FolderViewPB>, FlowyError>> getSpaces() {
    return getFolderView(depth: 1).then((result) {
      return result.fold(
        (folderView) => FlowyResult.success(
          folderView.children.where((e) => e.isSpace).toList(),
        ),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  /// Get the folder of the workspace.
  ///
  /// [rootViewId] is the id of the root view you want to get.
  /// [depth] controls the depth of the returned folder.
  Future<FlowyResult<FolderViewPB, FlowyError>> getFolderView({
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
    required SpacePermissionPB permission,
  }) {
    final payload = CreateSpacePayloadPB.create()
      ..workspaceId = workspaceId
      ..name = name
      ..spacePermission = permission
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
  /// [spaceId] is the id of the space you want to delete.
  Future<FlowyResult<void, FlowyError>> deleteSpace({
    required String spaceId,
  }) {
    final payload = MovePageToTrashPayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = spaceId;
    return FolderEventMovePageToTrash(payload).send();
  }

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
}

extension on ViewIconPB {
  String encode() {
    return jsonEncode(toProto3Json());
  }
}
