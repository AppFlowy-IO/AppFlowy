import 'package:flowy_sdk/protobuf/flowy-core-data-model/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

typedef WorkspaceAppsChangedCallback = void Function(Either<List<App>, FlowyError> appsOrFail);

typedef WorkspaceUpdatedCallback = void Function(String name, String desc);

abstract class IWorkspace {
  Future<Either<App, FlowyError>> createApp({required String name, String? desc});

  Future<Either<List<App>, FlowyError>> getApps();
}

abstract class IWorkspaceListener {
  void start({WorkspaceAppsChangedCallback? addAppCallback, WorkspaceUpdatedCallback? updatedCallback});

  Future<void> stop();
}
