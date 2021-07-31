import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc_modify.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-document/errors.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<DocInfo, DocError>> createDoc(
      {required String name, String? desc, String? text}) {
    final request =
        CreateDocRequest(id: docId, name: name, desc: desc, text: text);

    return EditorEventCreateDoc(request).send();
  }

  Future<Either<DocInfo, DocError>> readDoc() {
    final request = QueryDocRequest.create()..docId = docId;
    return EditorEventReadDocInfo(request).send();
  }

  Future<Either<DocData, DocError>> readDocData(String path) {
    final request = QueryDocDataRequest.create()
      ..docId = docId
      ..path = path;
    return EditorEventReadDocData(request).send();
  }

  Future<Either<Unit, DocError>> updateDoc(
      {String? name, String? desc, String? text}) {
    final request = UpdateDocRequest(id: docId, name: name, text: text);

    return EditorEventUpdateDoc(request).send();
  }

  Future<Either<Unit, DocError>> closeDoc(
      {String? name, String? desc, String? text}) {
    throw UnimplementedError();
  }
}
