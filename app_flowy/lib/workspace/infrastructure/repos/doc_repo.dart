import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-document/doc.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_update.pb.dart';

class DocRepository {
  final String docId;
  DocRepository({
    required this.docId,
  });

  Future<Either<Doc, WorkspaceError>> readDoc() {
    final request = OpenViewRequest.create()..viewId = docId;
    return WorkspaceEventOpenView(request).send();
  }

  Future<Either<Doc, WorkspaceError>> applyChangeset(
      {required Uint8List data}) {
    final request = ApplyChangesetRequest.create()
      ..viewId = docId
      ..data = data;
    return WorkspaceEventApplyChangeset(request).send();
  }

  Future<Either<Unit, WorkspaceError>> closeDoc(
      {String? name, String? desc, String? text}) {
    throw UnimplementedError();
  }
}
