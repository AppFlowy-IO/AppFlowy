import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';

import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-sync/text_block.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-text-block/entities.pb.dart';

class DocumentService {
  Future<Either<TextBlockPB, FlowyError>> openDocument({
    required String docId,
  }) async {
    await FolderEventSetLatestView(ViewIdPB(value: docId)).send();

    final payload = TextBlockIdPB(value: docId);
    return TextBlockEventGetTextBlock(payload).send();
  }

  Future<Either<Unit, FlowyError>> applyEdit({
    required String docId,
    required String data,
    String operations = "",
  }) {
    final payload = EditPayloadPB.create()
      ..textBlockId = docId
      ..operations = operations
      ..delta = data;
    return TextBlockEventApplyEdit(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument({required String docId}) {
    final request = ViewIdPB(value: docId);
    return FolderEventCloseView(request).send();
  }
}
