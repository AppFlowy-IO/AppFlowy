import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:dartz/dartz.dart';

class DocumentService {
  // unused now.
  Future<Either<FlowyError, Unit>> createDocument({
    required ViewPB view,
  }) async {
    final canOpen = await openDocument(viewId: view.id);
    if (canOpen.isRight()) {
      return const Right(unit);
    }
    final payload = CreateDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventCreateDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, DocumentDataPB>> openDocument({
    required String viewId,
  }) async {
    final payload = OpenDocumentPayloadPB()..documentId = viewId;
    final result = await DocumentEventOpenDocument(payload).send();
    return result.swap();
  }

  Future<Either<FlowyError, BlockPB>> getBlockFromDocument({
    required DocumentDataPB document,
    required String blockId,
  }) async {
    final block = document.blocks[blockId];

    if (block != null) {
      return right(block);
    }

    return left(
      FlowyError(
        msg: 'Block($blockId) not found in Document(${document.pageId})',
      ),
    );
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

  /// Upload a file to the cloud storage.
  Future<Either<FlowyError, UploadedFilePB>> uploadFile({
    required String localFilePath,
    bool isAsync = true,
  }) async {
    final workspace = await FolderEventReadCurrentWorkspace().send();
    return workspace.fold((l) async {
      final payload = UploadFileParamsPB(
        workspaceId: l.id,
        localFilePath: localFilePath,
        isAsync: isAsync,
      );
      final result = await DocumentEventUploadFile(payload).send();
      return result.swap();
    }, (r) async {
      return left(FlowyError(msg: 'Workspace not found'));
    });
  }

  /// Download a file from the cloud storage.
  Future<Either<FlowyError, Unit>> downloadFile({
    required String url,
  }) async {
    final workspace = await FolderEventReadCurrentWorkspace().send();
    return workspace.fold((l) async {
      final payload = UploadedFilePB(
        url: url,
      );
      final result = await DocumentEventDownloadFile(payload).send();
      return result.swap();
    }, (r) async {
      return left(FlowyError(msg: 'Workspace not found'));
    });
  }
}
