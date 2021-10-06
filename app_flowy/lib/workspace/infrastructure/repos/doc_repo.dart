import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_query.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<DocDelta, WorkspaceError>> readDoc() {
    final request = OpenViewRequest.create()..viewId = docId;
    return WorkspaceEventOpenView(request).send();
  }

  Future<Either<DocDelta, WorkspaceError>> applyDelta({required String data}) {
    final request = DocDelta.create()
      ..docId = docId
      ..data = data;
    return WorkspaceEventApplyDocDelta(request).send();
  }

  Future<Either<Unit, WorkspaceError>> closeDoc(
      {String? name, String? desc, String? text}) {
    throw UnimplementedError();
  }
}
