import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:flowy_editor/src/model/quill_delta.dart';
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
  Future<Either<Unit, WorkspaceError>> saveDoc({String? json}) {
    Log.debug("Saving doc");
    return repo.saveDoc(data: _encodeText(json));
  }

  @override
  Future<Either<Unit, WorkspaceError>> applyChangeset({String? json}) {
    return repo.applyChangeset(data: _encodeText(json));
  }
}

Uint8List _encodeText(String? json) {
  final data = utf8.encode(json ?? "");
  return Uint8List.fromList(data);
}

class EditorPersistenceImpl implements EditorPersistence {
  DocRepository repo;
  EditorPersistenceImpl({
    required this.repo,
  });

  @override
  Future<bool> save(List<dynamic> jsonList) async {
    Log.debug("Saving doc");
    final json = jsonEncode(jsonList);
    final data = utf8.encode(json);

    return repo.saveDoc(data: Uint8List.fromList(data)).then((result) {
      return result.fold(
        (l) => true,
        (r) => false,
      );
    });
  }
}
