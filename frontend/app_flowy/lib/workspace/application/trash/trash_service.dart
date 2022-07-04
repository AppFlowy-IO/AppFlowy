import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/trash.pb.dart';

class TrashService {
  Future<Either<RepeatedTrash, FlowyError>> readTrash() {
    return FolderEventReadTrash().send();
  }

  Future<Either<Unit, FlowyError>> putback(String trashId) {
    final id = TrashId.create()..id = trashId;

    return FolderEventPutbackTrash(id).send();
  }

  Future<Either<Unit, FlowyError>> deleteViews(List<Tuple2<String, TrashType>> trashList) {
    final items = trashList.map((trash) {
      return TrashId.create()
        ..id = trash.value1
        ..ty = trash.value2;
    });

    final ids = RepeatedTrashId(items: items);
    return FolderEventDeleteTrash(ids).send();
  }

  Future<Either<Unit, FlowyError>> restoreAll() {
    return FolderEventRestoreAllTrash().send();
  }

  Future<Either<Unit, FlowyError>> deleteAll() {
    return FolderEventDeleteAllTrash().send();
  }
}
