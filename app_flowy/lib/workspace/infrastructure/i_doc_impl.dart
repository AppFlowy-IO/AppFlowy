import 'dart:convert';

import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/errors.pb.dart';
import 'package:dartz/dartz.dart';

class IDocImpl extends IDoc {
  DocRepository repo;

  IDocImpl({required this.repo});

  @override
  Future<Either<Unit, EditorError>> closeDoc() {
    return repo.closeDoc();
  }

  @override
  Future<Either<Doc, EditorError>> readDoc() async {
    final docInfoOrFail = await repo.readDoc();
    return docInfoOrFail.fold(
      (info) => _loadDocument(info.path).then((result) => result.fold(
          (document) => left(Doc(info: info, data: document)),
          (error) => right(error))),
      (error) => right(error),
    );
  }

  @override
  Future<Either<Unit, EditorError>> updateDoc(
      {String? name, String? desc, String? text}) {
    final json = jsonEncode(text ?? "");
    return repo.updateDoc(name: name, desc: desc, text: json);
  }

  Future<Either<Document, EditorError>> _loadDocument(String path) {
    return repo.readDocData(path).then((docDataOrFail) {
      return docDataOrFail.fold(
        (docData) => left(_decodeToDocument(docData.text)),
        (error) => right(error),
      );
    });
  }

  Document _decodeToDocument(String text) {
    final json = jsonDecode(text);
    final document = Document.fromJson(json);
    return document;
  }
}
