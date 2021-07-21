import 'package:flowy_sdk/protobuf/flowy-workspace/protobuf.dart';
import 'package:dartz/dartz.dart';

abstract class IWorkspace {
  Future<Either<App, WorkspaceError>> createApp(
      {required String name, String? desc});

  Future<Either<List<App>, WorkspaceError>> getApps(
      {required String workspaceId});
}
