import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document-infra/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/view_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<DocDelta, WorkspaceError>> readDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventOpenView(request).send();
  }

  Future<Either<DocDelta, WorkspaceError>> composeDelta({required String data}) {
    final request = DocDelta.create()
      ..docId = docId
      ..data = data;
    return WorkspaceEventApplyDocDelta(request).send();
  }

  Future<Either<Unit, WorkspaceError>> closeDoc() {
    final request = QueryViewRequest(viewIds: [docId]);
    return WorkspaceEventCloseView(request).send();
  }
}
