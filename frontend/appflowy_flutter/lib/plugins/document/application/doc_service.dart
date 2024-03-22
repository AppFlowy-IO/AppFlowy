import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class DocumentService {
  // unused now.
  Future<FlowyResult<void, FlowyError>> createDocument({
    required ViewPB view,
  }) async {
    final canOpen = await openDocument(viewId: view.id);
    if (canOpen.isSuccess) {
      return FlowyResult.success(null);
    }
    final payload = CreateDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventCreateDocument(payload).send();
    return result;
  }

  Future<FlowyResult<DocumentDataPB, FlowyError>> openDocument({
    required String viewId,
  }) async {
    final payload = OpenDocumentPayloadPB()..documentId = viewId;
    final result = await DocumentEventOpenDocument(payload).send();
    return result;
  }

  Future<FlowyResult<DocumentDataPB, FlowyError>> getDocument({
    required String viewId,
  }) async {
    final payload = OpenDocumentPayloadPB()..documentId = viewId;
    final result = await DocumentEventGetDocumentData(payload).send();
    return result;
  }

  Future<FlowyResult<BlockPB, FlowyError>> getBlockFromDocument({
    required DocumentDataPB document,
    required String blockId,
  }) async {
    final block = document.blocks[blockId];

    if (block != null) {
      return FlowyResult.success(block);
    }

    return FlowyResult.failure(
      FlowyError(
        msg: 'Block($blockId) not found in Document(${document.pageId})',
      ),
    );
  }

  Future<FlowyResult<void, FlowyError>> closeDocument({
    required ViewPB view,
  }) async {
    final payload = CloseDocumentPayloadPB()..documentId = view.id;
    final result = await DocumentEventCloseDocument(payload).send();
    return result;
  }

  Future<FlowyResult<void, FlowyError>> applyAction({
    required String documentId,
    required Iterable<BlockActionPB> actions,
  }) async {
    final payload = ApplyActionPayloadPB(
      documentId: documentId,
      actions: actions,
    );
    final result = await DocumentEventApplyAction(payload).send();
    return result;
  }

  /// Creates a new external text.
  ///
  /// Normally, it's used to the block that needs sync long text.
  ///
  /// the delta parameter is the json representation of the delta.
  Future<FlowyResult<void, FlowyError>> createExternalText({
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
    return result;
  }

  /// Updates the external text.
  ///
  /// this function is compatible with the [createExternalText] function.
  ///
  /// the delta parameter is the json representation of the delta too.
  Future<FlowyResult<void, FlowyError>> updateExternalText({
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
    return result;
  }

  /// Upload a file to the cloud storage.
  Future<FlowyResult<UploadedFilePB, FlowyError>> uploadFile({
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
      return result;
    }, (r) async {
      return FlowyResult.failure(FlowyError(msg: 'Workspace not found'));
    });
  }

  /// Download a file from the cloud storage.
  Future<FlowyResult<void, FlowyError>> downloadFile({
    required String url,
  }) async {
    final workspace = await FolderEventReadCurrentWorkspace().send();
    return workspace.fold((l) async {
      final payload = UploadedFilePB(
        url: url,
      );
      final result = await DocumentEventDownloadFile(payload).send();
      return result;
    }, (r) async {
      return FlowyResult.failure(FlowyError(msg: 'Workspace not found'));
    });
  }
}
