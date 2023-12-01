import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:dartz/dartz.dart';

class RecentService {
  Future<Either<Unit, FlowyError>> updateRecentViews(
    List<String> viewIds,
    bool addInRecent,
  ) async {
    return FolderEventUpdateRecentViews(
      UpdateRecentViewPayloadPB(viewIds: viewIds, addInRecent: addInRecent),
    ).send();
  }

  Future<Either<RepeatedViewPB, FlowyError>> readRecentViews() {
    return FolderEventReadRecentViews().send();
  }
}
