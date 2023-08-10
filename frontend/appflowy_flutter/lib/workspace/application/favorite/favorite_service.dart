import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:dartz/dartz.dart';

class FavoriteService {
  Future<Either<RepeatedViewPB, FlowyError>> readFavorites() {
    return FolderEventReadFavorites().send();
  }

  Future<Either<Unit, FlowyError>> toggleFavorite(
    String viewId,
    bool favoriteStatus,
  ) async {
    final id = RepeatedViewIdPB.create()..items.add(viewId);
    return FolderEventToggleFavorite(id).send();
  }
}
