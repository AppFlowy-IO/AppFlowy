import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trash_bloc.freezed.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  TrashBloc()
      : _service = TrashService(),
        _listener = TrashListener(),
        super(TrashState.init()) {
    _dispatch();
  }

  final TrashService _service;
  final TrashListener _listener;

  void _dispatch() {
    on<TrashEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _listener.start(trashUpdated: _listenTrashUpdated);
          final result = await _service.readTrash();

          emit(
            result.fold(
              (object) => state.copyWith(
                objects: object.items,
                successOrFailure: FlowyResult.success(null),
              ),
              (error) =>
                  state.copyWith(successOrFailure: FlowyResult.failure(error)),
            ),
          );
        },
        didReceiveTrash: (e) async {
          emit(state.copyWith(objects: e.trash));
        },
        putback: (e) async {
          final result = await _service.putback(e.trashId);
          await _handleResult(result, emit);
        },
        delete: (e) async {
          final result = await _service.deleteViews([e.trash.id]);
          await _handleResult(result, emit);
        },
        deleteAll: (e) async {
          final result = await _service.deleteAll();
          await _handleResult(result, emit);
        },
        restoreAll: (e) async {
          final result = await _service.restoreAll();
          await _handleResult(result, emit);
        },
      );
    });
  }

  Future<void> _handleResult(
    FlowyResult<dynamic, FlowyError> result,
    Emitter<TrashState> emit,
  ) async {
    emit(
      result.fold(
        (l) => state.copyWith(successOrFailure: FlowyResult.success(null)),
        (error) => state.copyWith(successOrFailure: FlowyResult.failure(error)),
      ),
    );
  }

  void _listenTrashUpdated(
    FlowyResult<List<TrashPB>, FlowyError> trashOrFailed,
  ) {
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
    await _listener.close();
    return super.close();
  }
}

@freezed
class TrashEvent with _$TrashEvent {
  const factory TrashEvent.initial() = Initial;
  const factory TrashEvent.didReceiveTrash(List<TrashPB> trash) = ReceiveTrash;
  const factory TrashEvent.putback(String trashId) = Putback;
  const factory TrashEvent.delete(TrashPB trash) = Delete;
  const factory TrashEvent.restoreAll() = RestoreAll;
  const factory TrashEvent.deleteAll() = DeleteAll;
}

@freezed
class TrashState with _$TrashState {
  const factory TrashState({
    required List<TrashPB> objects,
    required FlowyResult<void, FlowyError> successOrFailure,
  }) = _TrashState;

  factory TrashState.init() => TrashState(
        objects: [],
        successOrFailure: FlowyResult.success(null),
      );
}
