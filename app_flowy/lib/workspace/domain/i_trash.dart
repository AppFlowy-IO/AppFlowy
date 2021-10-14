import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_create.pb.dart';

abstract class ITrash {
  Future<Either<List<Trash>, WorkspaceError>> readTrash();
}

typedef TrashUpdatedCallback = void Function(Either<List<Trash>, WorkspaceError> trashOrFailed);

abstract class ITrashListener {
  void start(TrashUpdatedCallback updateCallback);
  Future<void> stop();
}
