import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';

typedef WorkspaceAppsChangedCallback = void Function(Either<List<App>, WorkspaceError> appsOrFail);

typedef WorkspaceUpdatedCallback = void Function(String name, String desc);

abstract class IWorkspace {
  Future<Either<App, WorkspaceError>> createApp({required String name, String? desc});

  Future<Either<List<App>, WorkspaceError>> getApps();
}

abstract class IWorkspaceListener {
  void start({WorkspaceAppsChangedCallback? addAppCallback, WorkspaceUpdatedCallback? updatedCallback});

  Future<void> stop();
}
