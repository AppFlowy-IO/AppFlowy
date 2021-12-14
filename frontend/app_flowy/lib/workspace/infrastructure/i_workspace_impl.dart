import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:app_flowy/workspace/infrastructure/repos/workspace_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

export 'package:app_flowy/workspace/domain/i_workspace.dart';

class IWorkspaceImpl extends IWorkspace {
  WorkspaceRepo repo;
  IWorkspaceImpl({
    required this.repo,
  });

  @override
  Future<Either<App, FlowyError>> createApp({required String name, String? desc}) {
    return repo.createApp(name, desc ?? "");
  }

  @override
  Future<Either<List<App>, FlowyError>> getApps() {
    return repo.getApps().then((result) {
      return result.fold(
        (apps) => left(apps),
        (error) => right(error),
      );
    });
  }
}

class IWorkspaceListenerImpl extends IWorkspaceListener {
  WorkspaceListenerRepo repo;
  IWorkspaceListenerImpl({
    required this.repo,
  });

  @override
  void start({WorkspaceAppsChangedCallback? addAppCallback, WorkspaceUpdatedCallback? updatedCallback}) {
    repo.startListening(appsChanged: addAppCallback, update: updatedCallback);
  }

  @override
  Future<void> stop() async {
    await repo.close();
  }
}
