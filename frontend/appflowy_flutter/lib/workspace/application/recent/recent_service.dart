import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class RecentService {
  Future<FlowyResult<void, FlowyError>> updateRecentViews(
    List<String> viewIds,
    bool addInRecent,
  ) async {
    return FolderEventUpdateRecentViews(
      UpdateRecentViewPayloadPB(viewIds: viewIds, addInRecent: addInRecent),
    ).send();
  }

  Future<FlowyResult<RepeatedViewPB, FlowyError>> readRecentViews() {
    return FolderEventReadRecentViews().send();
  }
}
