import 'dart:convert';
import 'dart:async';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:dartz/dartz.dart';
// ignore: implementation_imports
import 'package:flowy_editor/src/model/quill_delta.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

class FlowyDoc {
  final DocDelta doc;
  final IDoc iDocImpl;
  late Document document;
  late StreamSubscription _subscription;

  FlowyDoc({required this.doc, required this.iDocImpl}) {
    document = _decodeJsonToDocument(doc.data);

    _subscription = document.changes.listen((event) {
      final delta = event.item2;
      final documentDelta = document.toDelta();
      _composeDelta(delta, documentDelta);
    });
  }

  String get id => doc.docId;

  Future<void> close() async {
    await _subscription.cancel();
  }

  void _composeDelta(Delta composedDelta, Delta documentDelta) async {
    final json = jsonEncode(composedDelta.toJson());
    Log.debug("Send json: $json");
    final result = await iDocImpl.composeDelta(json: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.data));
      if (documentDelta != rustDelta) {
        Log.error("Receive : $rustDelta");
        Log.error("Expected : $documentDelta");
      }
    }, (r) => null);
  }

  Document _decodeJsonToDocument(String data) {
    final json = jsonDecode(data);
    final document = Document.fromJson(json);
    return document;
  }
}

abstract class IDoc {
  Future<Either<DocDelta, WorkspaceError>> readDoc();
  Future<Either<DocDelta, WorkspaceError>> composeDelta({required String json});
  Future<Either<Unit, WorkspaceError>> closeDoc();
}
