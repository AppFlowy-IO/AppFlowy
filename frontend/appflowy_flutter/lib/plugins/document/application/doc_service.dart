import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';

import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';

class DocumentService {
  // unused now.
  Future<Either<FlowyError, Unit>> createDocument({
    required ViewPB view,
  }) async {
    final canOpen = await openDocument(view: view);
    if (canOpen.isRight()) {
      return const Right(unit);
    }
    final payload = CreateDocumentPayloadPBV2()..documentId = view.id;
    final result = await DocumentEvent2CreateDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, DocumentDataPB2>> openDocument({
    required ViewPB view,
  }) async {
    // set the latest view
    await FolderEventSetLatestView(ViewIdPB(value: view.id)).send();

    final payload = OpenDocumentPayloadPBV2()..documentId = view.id;
    final result = await DocumentEvent2OpenDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, Unit>> closeDocument({
    required ViewPB view,
  }) async {
    final payload = CloseDocumentPayloadPBV2()..documentId = view.id;
    final result = await DocumentEvent2CloseDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, Unit>> applyAction({
    required String documentId,
    required Iterable<BlockActionPB> actions,
  }) async {
    final payload = ApplyActionPayloadPBV2(
      documentId: documentId,
      actions: actions,
    );
    final result = await DocumentEvent2ApplyAction(payload).send();
    return result.swap();
  }
}
