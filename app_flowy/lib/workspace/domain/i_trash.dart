import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';

abstract class TrashObject {
  String get id;
}

abstract class ITrash {
  Future<Either<List<TrashObject>, WorkspaceError>> readTrash();
}

typedef TrashUpdateCallback = void Function(List<TrashObject>);

abstract class ITrashListener {
  void start();
  void setTrashUpdateCallback(TrashUpdateCallback trashUpdateCallback);
  Future<void> stop();
}
