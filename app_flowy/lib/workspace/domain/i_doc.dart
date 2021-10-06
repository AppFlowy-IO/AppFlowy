import 'dart:convert';

import 'package:flowy_editor/flowy_editor.dart';
import 'package:dartz/dartz.dart';
// ignore: implementation_imports
import 'package:flowy_editor/src/model/quill_delta.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class FlowyDoc implements EditorDeltaSender {
  final DocDelta doc;
  final IDoc iDocImpl;
  Document data;

  FlowyDoc({required this.doc, required this.data, required this.iDocImpl}) {
    data.sender = this;
  }
  String get id => doc.docId;

  @override
  void sendNewDelta(Delta changeset, Delta delta) async {
    final json = jsonEncode(changeset.toJson());
    Log.debug("Send json: $json");
    final result = await iDocImpl.applyChangeset(json: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.data));

      if (delta != rustDelta) {
        Log.error("Receive : $rustDelta");
        Log.error("Expected : $delta");
      } else {
        Log.info("Receive : $rustDelta");
        Log.info("Expected : $delta");
      }
    }, (r) => null);
  }
}

abstract class IDoc {
  Future<Either<DocDelta, WorkspaceError>> readDoc();
  Future<Either<DocDelta, WorkspaceError>> applyChangeset(
      {required String json});
  Future<Either<Unit, WorkspaceError>> closeDoc();
}
