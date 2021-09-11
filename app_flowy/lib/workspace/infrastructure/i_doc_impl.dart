import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class IDocImpl extends IDoc {
  DocRepository repo;

  IDocImpl({required this.repo});

  @override
  Future<Either<Unit, WorkspaceError>> closeDoc() {
    return repo.closeDoc();
  }

  @override
  Future<Either<FlowyDoc, WorkspaceError>> readDoc() async {
    final docOrFail = await repo.readDoc();

    return docOrFail.fold((doc) {
      return left(FlowyDoc(doc: doc, data: _decodeToDocument(doc.data)));
    }, (error) => right(error));
  }

  @override
  Future<Either<Unit, WorkspaceError>> updateDoc({String? text}) {
    final json = jsonEncode(text ?? "");
    return repo.updateDoc(text: json);
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
