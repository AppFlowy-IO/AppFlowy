import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';

class IViewImpl extends IView {
  ViewRepository repo;

  IViewImpl({required this.repo});

  @override
  View get view => repo.view;

  @override
  Future<Either<Unit, WorkspaceError>> pushIntoTrash() {
    return repo.updateView(isTrash: true);
  }

  @override
  Future<Either<Unit, WorkspaceError>> rename(String newName) {
    return repo.updateView(name: newName);
  }
}

class IViewListenerImpl extends IViewListener {
  final ViewListenerRepository repo;
  IViewListenerImpl({
    required this.repo,
  });

  @override
  void start({ViewUpdatedCallback? updatedCallback}) {
    repo.startWatching(update: updatedCallback);
  }

  @override
  Future<void> stop() async {
    await repo.close();
  }
}
