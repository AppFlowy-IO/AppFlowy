import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
export 'package:app_flowy/workspace/domain/i_app.dart';

class IAppImpl extends IApp {
  AppRepository repo;
  IAppImpl({
    required this.repo,
  });

  @override
  Future<Either<List<View>, FlowyError>> getViews() {
    return repo.getViews();
  }

  @override
  Future<Either<View, FlowyError>> createView({required String name, String? desc, required ViewType viewType}) {
    return repo.createView(name, desc ?? "", viewType).then((result) {
      return result.fold(
        (view) => left(view),
        (r) => right(r),
      );
    });
  }

  @override
  Future<Either<Unit, FlowyError>> delete() {
    return repo.delete();
  }

  @override
  Future<Either<Unit, FlowyError>> rename(String newName) {
    return repo.updateApp(name: newName);
  }
}

class IAppListenerhImpl extends IAppListenr {
  AppListenerRepository repo;
  IAppListenerhImpl({
    required this.repo,
  });

  @override
  Future<void> stop() async {
    await repo.close();
  }

  @override
  void start({AppViewsChangeCallback? viewsChangeCallback, AppUpdatedCallback? updatedCallback}) {
    repo.startListening(viewsChanged: viewsChangeCallback, update: updatedCallback);
  }
}
