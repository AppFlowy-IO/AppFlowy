import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class FavoriteService {
  Future<FlowyResult<RepeatedViewPB, FlowyError>> readFavorites() {
    return FolderEventReadFavorites().send();
  }

  Future<FlowyResult<void, FlowyError>> toggleFavorite(
    String viewId,
    bool favoriteStatus,
  ) async {
    final id = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventToggleFavorite(id).send();
  }
}
