import 'package:flowy_sdk/protobuf/flowy-core-data-model/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

typedef AppUpdatedCallback = void Function(App app);
typedef AppViewsChangeCallback = void Function(Either<List<View>, FlowyError> viewsOrFailed);

abstract class IApp {
  Future<Either<List<View>, FlowyError>> getViews();

  Future<Either<View, FlowyError>> createView({required String name, String? desc, required ViewType viewType});

  Future<Either<Unit, FlowyError>> delete();

  Future<Either<Unit, FlowyError>> rename(String newName);
}

abstract class IAppListenr {
  void start({AppViewsChangeCallback? viewsChangeCallback, AppUpdatedCallback? updatedCallback});

  Future<void> stop();
}
