import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'init_local_ai_bloc.freezed.dart';

class InitLocalAIBloc extends Bloc<InitLocalAIEvent, InitLocalAIState> {
  InitLocalAIBloc()
      : super(
          const InitLocalAIState(runningState: RunningStatePB.Connecting),
        ) {
    on<InitLocalAIEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    InitLocalAIEvent event,
    Emitter<InitLocalAIState> emit,
  ) async {
    await event.when(
      started: () async {},
    );
  }
}

@freezed
class InitLocalAIEvent with _$InitLocalAIEvent {
  const factory InitLocalAIEvent.started() = _Started;
}

@freezed
class InitLocalAIState with _$InitLocalAIState {
  const factory InitLocalAIState({
    required RunningStatePB runningState,
  }) = _InitLocalAIState;
}
