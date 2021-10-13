import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_delete.pb.dart';

class TrashRepo {
  Future<Either<RepeatedTrash, WorkspaceError>> readTrash() {
    return WorkspaceEventReadTrash().send();
  }

  Future<Either<Unit, WorkspaceError>> putback(String trashId) {
    final id = TrashIdentifier.create()..id = trashId;

    return WorkspaceEventPutbackTrash(id).send();
  }

  Future<Either<Unit, WorkspaceError>> delete(String trashId) {
    final id = TrashIdentifier.create()..id = trashId;
    return WorkspaceEventDeleteTrash(id).send();
  }
}
