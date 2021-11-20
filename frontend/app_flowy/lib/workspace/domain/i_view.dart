import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

typedef ViewUpdatedCallback = void Function(Either<View, WorkspaceError>);

typedef DeleteNotifierValue = Either<View, WorkspaceError>;
typedef UpdateNotifierValue = Either<View, WorkspaceError>;
typedef RestoreNotifierValue = Either<View, WorkspaceError>;

abstract class IView {
  View get view;

  Future<Either<Unit, WorkspaceError>> delete();

  Future<Either<View, WorkspaceError>> rename(String newName);

  Future<Either<Unit, WorkspaceError>> duplicate();
}

abstract class IViewListener {
  void start();

  PublishNotifier<UpdateNotifierValue> get updatedNotifier;

  PublishNotifier<DeleteNotifierValue> get deletedNotifier;

  PublishNotifier<RestoreNotifierValue> get restoredNotifier;

  Future<void> stop();
}
