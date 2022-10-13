import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';

import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-sync/document.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pb.dart';

class DocumentService {
  Future<Either<DocumentSnapshotPB, FlowyError>> openDocument({
    required String docId,
  }) async {
    await FolderEventSetLatestView(ViewIdPB(value: docId)).send();

    final payload = DocumentIdPB(value: docId);
    return DocumentEventGetDocument(payload).send();
  }

  Future<Either<Unit, FlowyError>> applyEdit({
    required String docId,
    required String data,
    String operations = "",
  }) {
    final payload = EditPayloadPB.create()
      ..docId = docId
      ..operations = operations
      ..operationsStr = data;
    return DocumentEventApplyEdit(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewIdPB(value: docId);
    return FolderEventCloseView(request).send();
  }
}
