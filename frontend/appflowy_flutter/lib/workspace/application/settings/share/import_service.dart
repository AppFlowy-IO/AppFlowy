import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
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
  static Future<FlowyResult<RepeatedViewPB, FlowyError>> importPages(
    String parentViewId,
    List<ImportValuePayloadPB> values,
  ) async {
    final request = ImportPayloadPB(
      parentViewId: parentViewId,
      values: values,
    );

    return FolderEventImportData(request).send();
  }

  static Future<FlowyResult<void, FlowyError>> importZipFiles(
    List<ImportZipPB> values,
  ) async {
    for (final value in values) {
      final result = await FolderEventImportZipFile(value).send();
      if (result.isFailure) {
        return result;
      }
    }
    return FlowyResult.success(null);
  }
}
