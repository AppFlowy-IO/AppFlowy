import 'package:flowy_sdk/protobuf/flowy-workspace/protobuf.dart';
import 'package:dartz/dartz.dart';

typedef WorkspaceAddAppCallback = void Function(
    Either<List<App>, WorkspaceError> appsOrFail);
typedef WorkspaceUpdatedCallback = void Function(String name, String desc);

abstract class IWorkspace {
  Future<Either<App, WorkspaceError>> createApp(
      {required String name, String? desc});

  Future<Either<List<App>, WorkspaceError>> getApps(
      {required String workspaceId});

  void startWatching(
      {WorkspaceAddAppCallback? addAppCallback,
      WorkspaceUpdatedCallback? updatedCallback});

  Future<void> stopWatching();
}
