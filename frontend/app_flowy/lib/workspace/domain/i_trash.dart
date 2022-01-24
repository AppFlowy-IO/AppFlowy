import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/trash.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

abstract class ITrash {
  Future<Either<List<Trash>, FlowyError>> readTrash();

  Future<Either<Unit, FlowyError>> putback(String trashId);

  Future<Either<Unit, FlowyError>> deleteViews(List<Tuple2<String, TrashType>> trashList);

  Future<Either<Unit, FlowyError>> restoreAll();

  Future<Either<Unit, FlowyError>> deleteAll();
}

typedef TrashUpdatedCallback = void Function(Either<List<Trash>, FlowyError> trashOrFailed);

abstract class ITrashListener {
  void start(TrashUpdatedCallback updateCallback);
  Future<void> stop();
}
