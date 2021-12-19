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

  Future<Either<DocDelta, FlowyError>> readDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventOpenView(request).send();
  }

  Future<Either<DocDelta, FlowyError>> composeDelta({required String data}) {
    final request = DocDelta.create()
      ..docId = docId
      ..data = data;
    return WorkspaceEventApplyDocDelta(request).send();
  }

  Future<Either<Unit, FlowyError>> closeDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventCloseView(request).send();
  }
}
