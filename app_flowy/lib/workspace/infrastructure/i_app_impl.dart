import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
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
        (view) => _createDoc(view),
        (r) => right(r),
      );
    });
  }

  Future<Either<View, workspace.WorkspaceError>> _createDoc(View view) async {
    switch (view.viewType) {
      case ViewType.Doc:
        final docRepo = DocRepository(docId: view.id);
        final result = await docRepo.createDoc(
            name: view.name, desc: "", text: "[{\"insert\":\"\\n\"}]");
        return result.fold((l) => left(view), (r) {
          return right(workspace.WorkspaceError(
              code: workspace.ErrorCode.Unknown, msg: r.msg));
        });
      default:
        return left(view);
    }
  }
}

class IAppWatchImpl extends IAppWatch {
  AppWatchRepository repo;
  IAppWatchImpl({
    required this.repo,
  });

  @override
  void startWatching(
      {AppCreateViewCallback? addViewCallback,
      AppUpdatedCallback? updatedCallback}) {
    repo.startWatching(createView: addViewCallback, update: updatedCallback);
  }

  @override
  Future<void> stopWatching() async {
    await repo.close();
  }
}
