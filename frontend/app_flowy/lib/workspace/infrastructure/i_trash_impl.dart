import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:app_flowy/workspace/infrastructure/repos/trash_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/trash_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class ITrashImpl implements ITrash {
  TrashRepo repo;

  ITrashImpl({required this.repo});

  @override
  Future<Either<List<Trash>, FlowyError>> readTrash() {
    return repo.readTrash().then((result) {
      return result.fold(
        (repeatedTrash) => left(repeatedTrash.items),
        (err) => right(err),
      );
    });
  }

  @override
  Future<Either<Unit, FlowyError>> putback(String trashId) {
    return repo.putback(trashId);
  }

  @override
  Future<Either<Unit, FlowyError>> deleteAll() {
    return repo.deleteAll();
  }

  @override
  Future<Either<Unit, FlowyError>> restoreAll() {
    return repo.restoreAll();
  }

  @override
  Future<Either<Unit, FlowyError>> deleteViews(List<Tuple2<String, TrashType>> trashList) {
    return repo.deleteViews(trashList);
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
