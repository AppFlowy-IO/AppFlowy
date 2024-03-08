import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/import.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_result/appflowy_result.dart';

class ImportBackendService {
  static Future<FlowyResult<void, FlowyError>> importData(
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
    return FolderEventImportData(payload).send();
  }
}

extension on ImportTypePB {
  ViewLayoutPB toLayout() {
    switch (this) {
      case ImportTypePB.HistoryDocument:
        return ViewLayoutPB.Document;
      case ImportTypePB.HistoryDatabase ||
            ImportTypePB.CSV ||
            ImportTypePB.RawDatabase:
        return ViewLayoutPB.Grid;
      default:
        throw UnimplementedError('Unsupported import type $this');
    }
  }
}
