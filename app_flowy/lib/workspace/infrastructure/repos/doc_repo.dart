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

  Future<Either<DocInfo, EditorError>> createDoc(
      {required String name, String? desc, String? text}) {
    final request =
        CreateDocRequest(id: docId, name: name, desc: desc, text: text);

    return EditorEventCreateDoc(request).send();
  }

  Future<Either<DocInfo, EditorError>> readDoc() {
    final request = QueryDocRequest.create()..docId = docId;
    return EditorEventReadDocInfo(request).send();
  }

  Future<Either<DocData, EditorError>> readDocData(String path) {
    final request = QueryDocDataRequest.create()
      ..docId = docId
      ..path = path;
    return EditorEventReadDocData(request).send();
  }

  Future<Either<Unit, EditorError>> updateDoc(
      {String? name, String? desc, String? text}) {
    final request = UpdateDocRequest(id: docId, name: name, text: text);

    return EditorEventUpdateDoc(request).send();
  }

  Future<Either<Unit, EditorError>> closeDoc(
      {String? name, String? desc, String? text}) {
    throw UnimplementedError();
  }
}
