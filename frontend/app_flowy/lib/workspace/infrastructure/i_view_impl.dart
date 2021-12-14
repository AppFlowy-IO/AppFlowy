import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class IViewImpl extends IView {
  ViewRepository repo;

  IViewImpl({required this.repo});

  @override
  View get view => repo.view;

  @override
  Future<Either<Unit, FlowyError>> delete() {
    return repo.delete().then((result) {
      return result.fold(
        (_) => left(unit),
        (error) => right(error),
      );
    });
  }

  @override
  Future<Either<View, FlowyError>> rename(String newName) {
    return repo.updateView(name: newName);
  }

  @override
  Future<Either<Unit, FlowyError>> duplicate() {
    return repo.duplicate();
  }
}

class IViewListenerImpl extends IViewListener {
  final ViewListenerRepository repo;
  IViewListenerImpl({
    required this.repo,
  });

  @override
  void start() {
    repo.start();
  }

  @override
  Future<void> stop() async {
    await repo.close();
  }

  @override
  PublishNotifier<DeleteNotifierValue> get deletedNotifier => repo.deletedNotifier;

  @override
  PublishNotifier<UpdateNotifierValue> get updatedNotifier => repo.updatedNotifier;

  @override
  PublishNotifier<RestoreNotifierValue> get restoredNotifier => repo.restoredNotifier;
}
