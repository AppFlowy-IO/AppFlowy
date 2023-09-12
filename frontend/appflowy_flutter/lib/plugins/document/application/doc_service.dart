import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart';

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

  /// Creates a new external text.
  ///
  /// Normally, it's used to the block that needs sync long text.
  ///
  /// the delta parameter is the json representation of the delta.
  Future<Either<FlowyError, Unit>> createExternalText({
    required String documentId,
    required String textId,
    String? delta,
  }) async {
    final payload = TextDeltaPayloadPB(
      documentId: documentId,
      textId: textId,
      delta: delta,
    );
    final result = await DocumentEventCreateText(payload).send();
    return result.swap();
  }

  /// Updates the external text.
  ///
  /// this function is compatible with the [createExternalText] function.
  ///
  /// the delta parameter is the json representation of the delta too.
  Future<Either<FlowyError, Unit>> updateExternalText({
    required String documentId,
    required String textId,
    String? delta,
  }) async {
    final payload = TextDeltaPayloadPB(
      documentId: documentId,
      textId: textId,
      delta: delta,
    );
    final result = await DocumentEventApplyTextDeltaEvent(payload).send();
    return result.swap();
  }
}
