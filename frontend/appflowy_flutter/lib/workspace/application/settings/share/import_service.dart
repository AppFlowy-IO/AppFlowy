import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/import.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:dartz/dartz.dart';

class ImportBackendService {
  static Future<Either<Unit, FlowyError>> importData(
    List<int> data,
    String name,
    String parentViewId,
    ImportTypePB importType,
  ) async {
    final payload = ImportPB.create()
      ..data = data
      ..parentViewId = parentViewId
      ..viewLayout = importType.toLayout()
      ..name = name
      ..importType = importType;
    return await FolderEventImportData(payload).send();
  }
}

extension on ImportTypePB {
  ViewLayoutPB toLayout() {
    switch (this) {
      case ImportTypePB.HistoryDocument:
        return ViewLayoutPB.Document;
      case ImportTypePB.HistoryDatabase || ImportTypePB.CSV:
        return ViewLayoutPB.Grid;
      default:
        throw UnimplementedError('Unsupported import type $this');
    }
  }
}
