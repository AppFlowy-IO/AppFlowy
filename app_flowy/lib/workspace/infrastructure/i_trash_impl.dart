import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:app_flowy/workspace/infrastructure/repos/trash_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_create.pb.dart';

class ITrashImpl implements ITrash {
  TrashRepo repo;

  ITrashImpl({required this.repo});

  @override
  Future<Either<List<Trash>, WorkspaceError>> readTrash() {
    return repo.readTrash().then((result) {
      return result.fold(
        (repeatedTrash) => left(repeatedTrash.items),
        (err) => right(err),
      );
    });
  }
}

class ITrashListenerImpl extends ITrashListener {
  TrashListenerRepo repo;
  ITrashListenerImpl({
    required this.repo,
  });

  @override
  Future<void> stop() async {
    await repo.close();
  }

  @override
  void start(TrashUpdatedCallback updateCallback) {
    repo.startListening(trashUpdated: updateCallback);
  }
}
