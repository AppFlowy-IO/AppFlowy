import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class DatabaseBackendService {
  static Future<FlowyResult<List<DatabaseMetaPB>, FlowyError>>
      getAllDatabases() {
    return DatabaseEventGetDatabases().send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l.items),
        (r) => FlowyResult.failure(r),
      );
    });
  }
}
