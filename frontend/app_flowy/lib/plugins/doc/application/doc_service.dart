import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pbenum.dart';

import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/entities.pb.dart';

class DocumentService {
  Future<Either<DocumentSnapshotPB, FlowyError>> openDocument({
    required ViewPB view,
  }) async {
    await FolderEventSetLatestView(ViewIdPB(value: view.id)).send();

    var payload = OpenDocumentContextPB()..documentId = view.id;
    switch (view.dataType) {
      case ViewDataFormatPB.DeltaFormat:
        payload.documentType = DocumentTypePB.Delta;
        break;
      default:
        payload.documentType = DocumentTypePB.NodeTree;
        break;
    }

    return DocumentEventGetDocument(payload).send();
  }

  Future<Either<Unit, FlowyError>> applyEdit({
    required String docId,
    required String operations,
  }) {
    final payload = EditPayloadPB.create()
      ..docId = docId
      ..operations = operations;
    return DocumentEventApplyEdit(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewIdPB(value: docId);
    return FolderEventCloseView(request).send();
  }
}
