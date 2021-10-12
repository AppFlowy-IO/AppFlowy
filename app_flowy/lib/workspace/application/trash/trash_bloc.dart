import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'trash_bloc.freezed.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final ITrash iTrash;
  TrashBloc(this.iTrash) : super(TrashState.init());

  @override
  Stream<TrashState> mapEventToState(TrashEvent event) async* {
    yield* event.map(
      initial: (e) async* {
        yield state;
      },
    );
  }
}

@freezed
class TrashEvent with _$TrashEvent {
  const factory TrashEvent.initial() = Initial;
}

@freezed
class TrashState with _$TrashState {
  const factory TrashState({
    required List<TrashObject> objects,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _TrashState;

  factory TrashState.init() => TrashState(
        objects: [],
        successOrFailure: left(unit),
      );
}
