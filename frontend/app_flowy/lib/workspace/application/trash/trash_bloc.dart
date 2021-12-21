import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/trash_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'trash_bloc.freezed.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final ITrash trasnManager;
  final ITrashListener listener;
  TrashBloc({required this.trasnManager, required this.listener}) : super(TrashState.init());

  @override
  Stream<TrashState> mapEventToState(TrashEvent event) async* {
    yield* event.map(
      initial: (e) async* {
        listener.start(_listenTrashUpdated);
        final result = await trasnManager.readTrash();
        yield result.fold(
          (objects) => state.copyWith(objects: objects, successOrFailure: left(unit)),
          (error) => state.copyWith(successOrFailure: right(error)),
        );
      },
      didReceiveTrash: (e) async* {
        yield state.copyWith(objects: e.trash);
      },
      putback: (e) async* {
        final result = await trasnManager.putback(e.trashId);
        yield* _handleResult(result);
      },
      delete: (e) async* {
        final result = await trasnManager.deleteViews([Tuple2(e.trash.id, e.trash.ty)]);
        yield* _handleResult(result);
      },
      deleteAll: (e) async* {
        final result = await trasnManager.deleteAll();
        yield* _handleResult(result);
      },
      restoreAll: (e) async* {
        final result = await trasnManager.restoreAll();
        yield* _handleResult(result);
      },
    );
  }

  Stream<TrashState> _handleResult(Either<dynamic, FlowyError> result) async* {
    yield result.fold(
      (l) => state.copyWith(successOrFailure: left(unit)),
      (error) => state.copyWith(successOrFailure: right(error)),
    );
  }

  void _listenTrashUpdated(Either<List<Trash>, FlowyError> trashOrFailed) {
    trashOrFailed.fold(
      (trash) {
        add(TrashEvent.didReceiveTrash(trash));
      },
      (error) {
        Log.error(error);
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class TrashEvent with _$TrashEvent {
  const factory TrashEvent.initial() = Initial;
  const factory TrashEvent.didReceiveTrash(List<Trash> trash) = ReceiveTrash;
  const factory TrashEvent.putback(String trashId) = Putback;
  const factory TrashEvent.delete(Trash trash) = Delete;
  const factory TrashEvent.restoreAll() = RestoreAll;
  const factory TrashEvent.deleteAll() = DeleteAll;
}

@freezed
class TrashState with _$TrashState {
  const factory TrashState({
    required List<Trash> objects,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _TrashState;

  factory TrashState.init() => TrashState(
        objects: [],
        successOrFailure: left(unit),
      );
}
