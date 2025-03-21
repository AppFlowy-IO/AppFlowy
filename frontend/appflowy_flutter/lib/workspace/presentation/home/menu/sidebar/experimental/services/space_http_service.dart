import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';

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
