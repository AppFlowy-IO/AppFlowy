import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/doc_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/doc_modify.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/doc_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/errors.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<DocDescription, EditorError>> createDoc(
      {required String name, String? desc}) {
    final request = CreateDocRequest(id: docId, name: name, desc: desc);

    return EditorEventCreateDoc(request).send();
  }

  Future<Either<Doc, EditorError>> readDoc() {
    final request = QueryDocRequest.create()..docId = docId;
    return EditorEventReadDoc(request).send();
  }

  Future<Either<Unit, EditorError>> updateDoc(
      {String? name, String? desc, String? text}) {
    final request = UpdateDocRequest(id: docId, name: name, text: text);

    return EditorEventUpdateDoc(request).send();
  }
}
