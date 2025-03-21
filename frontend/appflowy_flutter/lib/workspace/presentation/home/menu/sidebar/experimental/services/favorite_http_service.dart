import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class FavoriteHttpService {
  FavoriteHttpService({required this.workspaceId});

  final String workspaceId;

  /// Get the favorite pages of the workspace.
  Future<FlowyResult<List<FavoriteFolderViewPB>, FlowyError>>
      getFavoritePages() {
    final payload = GetFavoritePagesPayloadPB.create()
      ..workspaceId = workspaceId;

    return FolderEventGetFavoritePages(payload).send().then((result) {
      return result.fold(
        (favoritePages) => FlowySuccess(favoritePages.items.toList()),
        (error) => FlowyFailure(error),
      );
    });
  }

  /// Add a page to the favorite pages of the workspace.
  Future<FlowyResult<void, FlowyError>> addFavoritePage({
    required String pageId,
    bool isPinned = true,
  }) {
    final payload = UpdateFavoritePagePayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = pageId
      ..isFavorite = true
      ..isPinned = isPinned;

    return FolderEventUpdateFavoritePage(payload).send();
  }

  /// Remove a page from the favorite pages of the workspace.
  Future<FlowyResult<void, FlowyError>> removeFavoritePage({
    required String pageId,
    bool isPinned = false,
  }) {
    final payload = UpdateFavoritePagePayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = pageId
      ..isFavorite = false
      ..isPinned = isPinned;

    return FolderEventUpdateFavoritePage(payload).send();
  }

  /// Pin a page to the favorite pages of the workspace.
  Future<FlowyResult<void, FlowyError>> pinFavoritePage({
    required String pageId,
  }) {
    final payload = UpdateFavoritePagePayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = pageId
      ..isFavorite = true
      ..isPinned = true;

    return FolderEventUpdateFavoritePage(payload).send();
  }

  /// Unpin a page from the favorite pages of the workspace.
  Future<FlowyResult<void, FlowyError>> unpinFavoritePage({
    required String pageId,
  }) {
    final payload = UpdateFavoritePagePayloadPB.create()
      ..workspaceId = workspaceId
      ..viewId = pageId
      ..isFavorite = true
      ..isPinned = false;

    return FolderEventUpdateFavoritePage(payload).send();
  }
}
