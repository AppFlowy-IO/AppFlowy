import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:dartz/dartz.dart';

class IViewImpl extends IView {
  ViewRepository repo;

  IViewImpl({required this.repo});

  @override
  Future<Either<View, WorkspaceError>> readView() {
    return repo.readView();
  }
}

class IViewWatchImpl extends IViewWatch {
  final ViewWatchRepository repo;
  IViewWatchImpl({
    required this.repo,
  });

  @override
  void startWatching({ViewUpdatedCallback? updatedCallback}) {
    repo.startWatching(updatedCallback: updatedCallback);
  }

  @override
  Future<void> stopWatching() async {
    await repo.close();
  }
}
