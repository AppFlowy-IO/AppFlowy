import 'dart:convert';

import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';

class FavoriteService {
  Future<FlowyResult<RepeatedFavoriteViewPB, FlowyError>> readFavorites() {
    final result = FolderEventReadFavorites().send();
    return result.then((result) {
      return result.fold(
        (favoriteViews) {
          return FlowyResult.success(
            RepeatedFavoriteViewPB(
              items: favoriteViews.items.where((e) => !e.item.isSpace),
            ),
          );
        },
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> toggleFavorite(
    String viewId,
    bool favoriteStatus,
  ) async {
    final id = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventToggleFavorite(id).send();
  }

  Future<FlowyResult<void, FlowyError>> pinFavorite(ViewPB view) async {
    return pinOrUnpinFavorite(view, true);
  }

  Future<FlowyResult<void, FlowyError>> unpinFavorite(ViewPB view) async {
    return pinOrUnpinFavorite(view, false);
  }

  Future<FlowyResult<void, FlowyError>> pinOrUnpinFavorite(
    ViewPB view,
    bool isPinned,
  ) async {
    try {
      final current =
          view.extra.isNotEmpty ? jsonDecode(view.extra) : <String, dynamic>{};
      final merged = mergeMaps(
        current,
        <String, dynamic>{ViewExtKeys.isPinnedKey: isPinned},
      );
      await ViewBackendService.updateView(
        viewId: view.id,
        extra: jsonEncode(merged),
      );
    } catch (e) {
      return FlowyResult.failure(FlowyError(msg: 'Failed to pin favorite: $e'));
    }

    return FlowyResult.success(null);
  }
}
