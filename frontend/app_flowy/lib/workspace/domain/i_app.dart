import 'package:flowy_sdk/protobuf/flowy-workspace-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';

typedef AppUpdatedCallback = void Function(App app);
typedef AppViewsChangeCallback = void Function(Either<List<View>, WorkspaceError> viewsOrFailed);

abstract class IApp {
  Future<Either<List<View>, WorkspaceError>> getViews();

  Future<Either<View, WorkspaceError>> createView({required String name, String? desc, required ViewType viewType});

  Future<Either<Unit, WorkspaceError>> delete();

  Future<Either<Unit, WorkspaceError>> rename(String newName);
}

abstract class IAppListenr {
  void start({AppViewsChangeCallback? viewsChangeCallback, AppUpdatedCallback? updatedCallback});

  Future<void> stop();
}
