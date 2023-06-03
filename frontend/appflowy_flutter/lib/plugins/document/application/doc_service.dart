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
    final payload = CreateDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventCreateDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, DocumentDataPB>> openDocument({
    required ViewPB view,
  }) async {
    final payload = OpenDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventOpenDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, Unit>> closeDocument({
    required ViewPB view,
  }) async {
    final payload = CloseDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventCloseDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, Unit>> applyAction({
    required String documentId,
    required Iterable<BlockActionPB> actions,
  }) async {
    final payload = ApplyActionPayloadPB(
      documentId: documentId,
      actions: actions,
    );
    final result = await DocumentEventApplyAction(payload).send();
    return result.swap();
  }
}
