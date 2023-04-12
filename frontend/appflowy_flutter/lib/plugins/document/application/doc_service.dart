import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';

import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';

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

  Future<Either<DocumentDataPB2, FlowyError>> openDocumentV2({
    required ViewPB view,
  }) async {
    await FolderEventSetLatestView(ViewIdPB(value: view.id)).send();

    final payload = OpenDocumentPayloadPBV2()..documentId = view.id;

    return DocumentEvent2OpenDocument(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocumentV2({
    required ViewPB view,
  }) async {
    final payload = CloseDocumentPayloadPBV2()..documentId = view.id;
    return DocumentEvent2CloseDocument(payload).send();
  }

  Future<Either<Unit, FlowyError>> applyAction({
    required ViewPB view,
    required List<BlockActionPB> actions,
  }) async {
    final payload = ApplyActionPayloadPBV2(
      documentId: view.id,
      actions: actions,
    );
    return DocumentEvent2ApplyAction(payload).send();
  }
}
