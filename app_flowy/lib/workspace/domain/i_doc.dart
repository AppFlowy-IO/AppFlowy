import 'dart:convert';

import 'package:flowy_editor/flowy_editor.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_editor/src/model/quill_delta.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class FlowyDoc implements EditorChangesetSender {
  final Doc doc;
  final IDoc iDocImpl;
  Document data;

  FlowyDoc({required this.doc, required this.data, required this.iDocImpl}) {
    data.sender = this;
  }
  String get id => doc.id;

  @override
  void sendDelta(Delta delta) {
    final json = jsonEncode(delta.toJson());
    Log.debug("Send json: $json");
    iDocImpl.applyChangeset(json: json);
  }
}

abstract class IDoc {
  Future<Either<Doc, WorkspaceError>> readDoc();
  Future<Either<Unit, WorkspaceError>> saveDoc({String? json});
  Future<Either<Unit, WorkspaceError>> applyChangeset({String? json});
  Future<Either<Unit, WorkspaceError>> closeDoc();
}
