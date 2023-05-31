import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class DatabaseLayoutBackendService {
  final String viewId;

  DatabaseLayoutBackendService(this.viewId);

  Future<Either<Unit, FlowyError>> updateLayout({
    required String fieldId,
    required DatabaseLayoutPB layout,
  }) {
    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..layoutType = layout;

    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => left(l),
        (err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }
}
