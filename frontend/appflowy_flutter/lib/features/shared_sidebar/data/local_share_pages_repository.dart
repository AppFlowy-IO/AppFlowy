import 'package:appflowy/features/shared_sidebar/data/share_pages_repository.dart';
import 'package:appflowy/features/shared_sidebar/models/shared_page.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class LocalSharePagesRepository implements SharePagesRepository {
  @override
  Future<FlowyResult<SharedPages, FlowyError>> getSharedPages() async {
    final pages = [
      SharedPage(
        view: ViewPB()
          ..id = '1'
          ..name = 'Welcome Page',
        accessLevel: AFAccessLevelPB.FullAccess,
      ),
      SharedPage(
        view: ViewPB()
          ..id = '2'
          ..name = 'Project Plan',
        accessLevel: AFAccessLevelPB.ReadAndWrite,
      ),
      SharedPage(
        view: ViewPB()
          ..id = '3'
          ..name = 'Readme',
        accessLevel: AFAccessLevelPB.ReadOnly,
      ),
    ];
    return FlowyResult.success(pages);
  }
}
