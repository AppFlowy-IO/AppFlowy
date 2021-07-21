import 'package:app_flowy/home/infrastructure/repos/app_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:app_flowy/home/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';

export 'package:app_flowy/home/domain/i_app.dart';

class IAppImpl extends IApp {
  AppRepository repo;
  IAppImpl({
    required this.repo,
  });

  @override
  Future<Either<List<View>, WorkspaceError>> getViews({required String appId}) {
    return repo.getViews(appId: appId);
  }

  @override
  Future<Either<View, WorkspaceError>> createView(
      {required String appId,
      required String name,
      String? desc,
      required ViewType viewType}) {
    return repo.createView(appId, name, desc ?? "", viewType);
  }

  @override
  void startWatching(
      {AppAddViewCallback? addViewCallback,
      AppUpdatedCallback? updatedCallback}) {
    repo.startWatching(
        addViewCallback: addViewCallback, updatedCallback: updatedCallback);
  }

  @override
  Future<void> stopWatching() async {
    await repo.close();
  }
}
