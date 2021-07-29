import 'package:flowy_sdk/protobuf/flowy-workspace/protobuf.dart';
import 'package:dartz/dartz.dart';

typedef WorkspaceCreateAppCallback = void Function(
    Either<List<App>, WorkspaceError> appsOrFail);

typedef WorkspaceUpdatedCallback = void Function(String name, String desc);

typedef WorkspaceDeleteAppCallback = void Function(
    Either<List<App>, WorkspaceError> appsOrFail);

abstract class IWorkspace {
  Future<Either<App, WorkspaceError>> createApp(
      {required String name, String? desc});

  Future<Either<List<App>, WorkspaceError>> getApps();
}

abstract class IWorkspaceWatch {
  void startWatching(
      {WorkspaceCreateAppCallback? addAppCallback,
      WorkspaceUpdatedCallback? updatedCallback});

  Future<void> stopWatching();
}
