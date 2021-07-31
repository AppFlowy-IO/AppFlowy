import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_sdk/protobuf/flowy-document/errors.pb.dart';

import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';

class IDocImpl extends IDoc {
  DocRepository repo;

  IDocImpl({required this.repo});

  @override
  Future<Either<Unit, DocError>> closeDoc() {
    return repo.closeDoc();
  }

  @override
  Future<Either<Doc, DocError>> readDoc() async {
    final docInfoOrFail = await repo.readDoc();
    return docInfoOrFail.fold(
      (info) => _loadDocument(info.path).then((result) => result.fold(
          (document) => left(Doc(info: info, data: document)),
          (error) => right(error))),
      (error) => right(error),
    );
  }

  @override
  Future<Either<Unit, DocError>> updateDoc(
      {String? name, String? desc, String? text}) {
    final json = jsonEncode(text ?? "");
    return repo.updateDoc(name: name, desc: desc, text: json);
  }

  Future<Either<Document, DocError>> _loadDocument(String path) {
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

class EditorPersistenceImpl extends EditorPersistence {
  DocRepository repo;
  EditorPersistenceImpl({
    required this.repo,
  });

  @override
  Future<bool> save(List<dynamic> jsonList) async {
    final json = jsonEncode(jsonList);
    return repo.updateDoc(text: json).then((result) {
      return result.fold(
        (l) => true,
        (r) => false,
      );
    });
  }
}
