import 'package:app_flowy/home/domain/i_workspace.dart';
import 'package:app_flowy/home/infrastructure/repos/workspace_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

export 'package:app_flowy/home/domain/i_workspace.dart';

class IWorkspaceImpl extends IWorkspace {
  WorkspaceRepository repo;
  IWorkspaceImpl({
    required this.repo,
  });

  @override
  Future<Either<App, WorkspaceError>> createApp(
      {required String name, String? desc}) {
    return repo.createApp(name, desc ?? "");
  }

  @override
  Future<Either<List<App>, WorkspaceError>> getApps(
      {required String workspaceId}) {
    return repo.getApps(workspaceId: workspaceId);
  }
}
