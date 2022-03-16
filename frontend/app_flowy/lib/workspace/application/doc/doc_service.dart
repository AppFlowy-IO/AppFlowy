import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-collaboration/document_info.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class DocumentService {
  Future<Either<BlockDelta, FlowyError>> openDocument({
    required String docId,
  }) async {
    await FolderEventSetLatestView(ViewId(value: docId)).send();

    final payload = BlockId(value: docId);
    return BlockEventGetBlockData(payload).send();
  }

  Future<Either<BlockDelta, FlowyError>> composeDelta({required String docId, required String data}) {
    final payload = BlockDelta.create()
      ..blockId = docId
      ..deltaStr = data;
    return BlockEventApplyDelta(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewId(value: docId);
    return FolderEventCloseView(request).send();
  }
}
