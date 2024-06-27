import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/import.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_result/appflowy_result.dart';

class ImportPayload {
  ImportPayload({
    required this.name,
    required this.data,
    required this.layout,
  });

  final String name;
  final List<int> data;
  final ViewLayoutPB layout;
}

class ImportBackendService {
  static Future<FlowyResult<void, FlowyError>> importPages(
    String parentViewId,
    List<ImportValuePayloadPB> values,
  ) async {
    final request = ImportPayloadPB(
      parentViewId: parentViewId,
      values: values,
    );

    return FolderEventImportData(request).send();
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
