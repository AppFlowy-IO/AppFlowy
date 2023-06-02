import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/share_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class BackendExportService {
  static Future<Either<DatabaseExportDataPB, FlowyError>> exportDatabaseAsCSV(
    String viewId,
  ) async {
    final payload = DatabaseViewIdPB.create()..value = viewId;
    return DatabaseEventExportCSV(payload).send();
  }
}
