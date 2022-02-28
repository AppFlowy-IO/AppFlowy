import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/trash.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'trash_listener.dart';
import 'dart:async';
import 'package:flowy_sdk/dispatch/dispatch.dart';

part 'trash_bloc.freezed.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final TrashListener listener;
  TrashBloc({required this.listener}) : super(TrashState.init()) {
    on<TrashEvent>((event, emit) async {
      await event.map(initial: (e) async {
        listener.startListening(trashUpdated: _listenTrashUpdated);

        final result = await FolderEventReadTrash().send();

        emit(result.fold(
          (object) => state.copyWith(objects: object.items, successOrFailure: left(unit)),
          (error) => state.copyWith(successOrFailure: right(error)),
        ));
      }, didReceiveTrash: (e) async {
        emit(state.copyWith(objects: e.trash));
      }, putback: (e) async {
        final id = TrashId.create()..id = e.trashId;
        final result = await FolderEventPutbackTrash(id).send();

        await _handleResult(result, emit);
      }, delete: (e) async {
        final result = await _deleteViews([Tuple2(e.trash.id, e.trash.ty)]);
        await _handleResult(result, emit);
      }, deleteAll: (e) async {
        final result = await FolderEventDeleteAllTrash().send();
        await _handleResult(result, emit);
      }, restoreAll: (e) async {
        final result = await FolderEventRestoreAllTrash().send();
        await _handleResult(result, emit);
      });
    });
  }

  Future<void> _handleResult(Either<dynamic, FlowyError> result, Emitter<TrashState> emit) async {
    emit(result.fold(
      (l) => state.copyWith(successOrFailure: left(unit)),
      (error) => state.copyWith(successOrFailure: right(error)),
    ));
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

  Future<Either<Unit, FlowyError>> _deleteViews(List<Tuple2<String, TrashType>> trashList) {
    final items = trashList.map((trash) {
      return TrashId.create()
        ..id = trash.value1
        ..ty = trash.value2;
    });

    final ids = RepeatedTrashId(items: items);
    return FolderEventDeleteTrash(ids).send();
  }

  @override
  Future<void> close() async {
    await listener.close();
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
