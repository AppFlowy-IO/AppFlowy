import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart' as workspace;
import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
export 'package:app_flowy/workspace/domain/i_app.dart';

class IAppImpl extends IApp {
  AppRepository repo;
  IAppImpl({
    required this.repo,
  });

  @override
  Future<Either<List<View>, workspace.WorkspaceError>> getViews() {
    return repo.getViews();
  }

  @override
  Future<Either<View, workspace.WorkspaceError>> createView(
      {required String name, String? desc, required ViewType viewType}) {
    return repo.createView(name, desc ?? "", viewType).then((result) {
      return result.fold(
        (view) => left(view),
        (r) => right(r),
      );
    });
  }
}

class IAppListenerhImpl extends IAppListenr {
  AppListenerRepository repo;
  IAppListenerhImpl({
    required this.repo,
  });

  @override
  void start({AppCreateViewCallback? addViewCallback, AppUpdatedCallback? updatedCallback}) {
    repo.startListen(createView: addViewCallback, update: updatedCallback);
  }

  @override
  Future<void> stop() async {
    await repo.close();
  }
}
