import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-collaboration/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/view_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<DocumentDelta, FlowyError>> readDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventOpenView(request).send();
  }

  Future<Either<DocumentDelta, FlowyError>> composeDelta({required String data}) {
    final request = DocumentDelta.create()
      ..docId = docId
      ..deltaJson = data;
    return WorkspaceEventApplyDocDelta(request).send();
  }

  Future<Either<Unit, FlowyError>> closeDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventCloseView(request).send();
  }
}
