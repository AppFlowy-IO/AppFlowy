import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';

import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-sync/text_block_info.pb.dart';

class DocumentService {
  Future<Either<TextBlockDelta, FlowyError>> openDocument({
    required String docId,
  }) async {
    await FolderEventSetLatestView(ViewId(value: docId)).send();

    final payload = TextBlockId(value: docId);
    return BlockEventGetBlockData(payload).send();
  }

  Future<Either<TextBlockDelta, FlowyError>> composeDelta({required String docId, required String data}) {
    final payload = TextBlockDelta.create()
      ..blockId = docId
      ..deltaStr = data;
    return BlockEventApplyDelta(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewId(value: docId);
    return FolderEventCloseView(request).send();
  }
}
