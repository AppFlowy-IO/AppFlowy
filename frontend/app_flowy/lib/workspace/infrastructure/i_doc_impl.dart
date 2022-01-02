import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-collaboration/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class IDocImpl extends IDoc {
  DocRepository repo;

  IDocImpl({required this.repo});

  @override
  Future<Either<Unit, FlowyError>> closeDoc() {
    return repo.closeDoc();
  }

  @override
  Future<Either<DocumentDelta, FlowyError>> readDoc() async {
    final docOrFail = await repo.readDoc();
    return docOrFail;
  }

  @override
  Future<Either<DocumentDelta, FlowyError>> composeDelta({required String json}) {
    return repo.composeDelta(data: json);
  }
}

// ignore: unused_element
Uint8List _encodeJsonText(String? json) {
  final data = utf8.encode(json ?? "");
  return Uint8List.fromList(data);
}
