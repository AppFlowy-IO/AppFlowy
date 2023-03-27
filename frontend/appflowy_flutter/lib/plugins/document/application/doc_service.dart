import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';

import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';

class DocumentService {
  Future<Either<DocumentDataPB, FlowyError>> openDocument({
    required ViewPB view,
  }) async {
    await FolderEventSetLatestView(ViewIdPB(value: view.id)).send();

    final payload = OpenDocumentPayloadPB()
      ..documentId = view.id
      ..version = DocumentVersionPB.V1;
    // switch (view.dataFormat) {
    //   case ViewDataFormatPB.DeltaFormat:
    //     payload.documentVersion = DocumentVersionPB.V0;
    //     break;
    //   default:
    //     break;
    // }

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
    final payload = ViewIdPB(value: docId);
    return FolderEventCloseView(payload).send();
  }
}
