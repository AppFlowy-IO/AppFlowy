import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class IDocImpl extends IDoc {
  DocRepository repo;

  IDocImpl({required this.repo});

  @override
  Future<Either<Unit, WorkspaceError>> closeDoc() {
    return repo.closeDoc();
  }

  @override
  Future<Either<Doc, WorkspaceError>> readDoc() async {
    final docOrFail = await repo.readDoc();
    return docOrFail;
  }

  @override
  Future<Either<Unit, WorkspaceError>> saveDoc({String? text}) {
    Log.debug("Saving doc");
    final json = jsonEncode(text ?? "");
    return repo.updateDoc(text: json);
  }

  @override
  Future<Either<Unit, WorkspaceError>> updateWithChangeset({String? text}) {
    return repo.updateWithChangeset(text: text);
  }
}

class EditorPersistenceImpl extends EditorPersistence {
  DocRepository repo;
  EditorPersistenceImpl({
    required this.repo,
  });

  @override
  Future<bool> save(List<dynamic> jsonList) async {
    Log.debug("Saving doc");
    final json = jsonEncode(jsonList);
    return repo.updateDoc(text: json).then((result) {
      return result.fold(
        (l) => true,
        (r) => false,
      );
    });
  }
}
