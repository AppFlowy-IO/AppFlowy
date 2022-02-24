import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-collaboration/document_info.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class DocumentRepository {
  final String docId;
  DocumentRepository({
    required this.docId,
  });

  Future<Either<DocumentDelta, FlowyError>> openDocument() {
    final request = ViewId(viewId: docId);
    return FolderEventOpenView(request).send();
  }

  Future<Either<DocumentDelta, FlowyError>> composeDelta({required String data}) {
    final request = DocumentDelta.create()
      ..docId = docId
      ..deltaJson = data;
    return FolderEventApplyDocDelta(request).send();
  }

  Future<Either<Unit, FlowyError>> closeDocument() {
    final request = ViewId(viewId: docId);
    return FolderEventCloseView(request).send();
  }
}
