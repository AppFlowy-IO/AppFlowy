import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_create.pb.dart';

abstract class ITrash {
  Future<Either<List<Trash>, WorkspaceError>> readTrash();

  Future<Either<Unit, WorkspaceError>> putback(String trashId);

  Future<Either<Unit, WorkspaceError>> deleteViews(List<Tuple2<String, TrashType>> trashList);

  Future<Either<Unit, WorkspaceError>> restoreAll();

  Future<Either<Unit, WorkspaceError>> deleteAll();
}

typedef TrashUpdatedCallback = void Function(Either<List<Trash>, WorkspaceError> trashOrFailed);

abstract class ITrashListener {
  void start(TrashUpdatedCallback updateCallback);
  Future<void> stop();
}
