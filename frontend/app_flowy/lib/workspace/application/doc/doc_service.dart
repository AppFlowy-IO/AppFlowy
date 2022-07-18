import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';

import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-sync/text_block.pb.dart';

class DocumentService {
  Future<Either<TextBlockDeltaPB, FlowyError>> openDocument({
    required String docId,
  }) async {
    await FolderEventSetLatestView(ViewId(value: docId)).send();

    final payload = TextBlockIdPB(value: docId);
    return TextBlockEventGetBlockData(payload).send();
  }

  Future<Either<TextBlockDeltaPB, FlowyError>> composeDelta({required String docId, required String data}) {
    final payload = TextBlockDeltaPB.create()
      ..blockId = docId
      ..deltaStr = data;
    return TextBlockEventApplyDelta(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewId(value: docId);
    return FolderEventCloseView(request).send();
  }
}
