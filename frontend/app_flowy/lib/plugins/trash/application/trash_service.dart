import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';

class TrashService {
  Future<Either<RepeatedTrashPB, FlowyError>> readTrash() {
    return FolderEventReadTrash().send();
  }

  Future<Either<Unit, FlowyError>> putback(String trashId) {
    final id = TrashIdPB.create()..id = trashId;

    return FolderEventPutbackTrash(id).send();
  }

  Future<Either<Unit, FlowyError>> deleteViews(
      List<Tuple2<String, TrashType>> trashList) {
    final items = trashList.map((trash) {
      return TrashIdPB.create()
        ..id = trash.value1
        ..ty = trash.value2;
    });

    final ids = RepeatedTrashIdPB(items: items);
    return FolderEventDeleteTrash(ids).send();
  }

  Future<Either<Unit, FlowyError>> restoreAll() {
    return FolderEventRestoreAllTrash().send();
  }

  Future<Either<Unit, FlowyError>> deleteAll() {
    return FolderEventDeleteAllTrash().send();
  }
}
