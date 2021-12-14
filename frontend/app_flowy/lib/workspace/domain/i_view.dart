import 'package:flowy_sdk/protobuf/flowy-core-infra/view_create.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

typedef ViewUpdatedCallback = void Function(Either<View, FlowyError>);

typedef DeleteNotifierValue = Either<View, FlowyError>;
typedef UpdateNotifierValue = Either<View, FlowyError>;
typedef RestoreNotifierValue = Either<View, FlowyError>;

abstract class IView {
  View get view;

  Future<Either<Unit, FlowyError>> delete();

  Future<Either<View, FlowyError>> rename(String newName);

  Future<Either<Unit, FlowyError>> duplicate();
}

abstract class IViewListener {
  void start();

  PublishNotifier<UpdateNotifierValue> get updatedNotifier;

  PublishNotifier<DeleteNotifierValue> get deletedNotifier;

  PublishNotifier<RestoreNotifierValue> get restoredNotifier;

  Future<void> stop();
}
