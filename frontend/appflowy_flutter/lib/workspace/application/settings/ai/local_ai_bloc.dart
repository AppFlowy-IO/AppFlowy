import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'local_ai_bloc.freezed.dart';

class LocalAIToggleBloc extends Bloc<LocalAIToggleEvent, LocalAIToggleState> {
  LocalAIToggleBloc() : super(const LocalAIToggleState()) {
    on<LocalAIToggleEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    LocalAIToggleEvent event,
    Emitter<LocalAIToggleState> emit,
  ) async {
    await event.when(
      started: () async {
        final result = await ChatEventGetLocalAIState().send();
        _handleResult(emit, result);
      },
      toggle: () async {
        emit(
          state.copyWith(
            pageIndicator: const LocalAIToggleStateIndicator.loading(),
          ),
        );
        unawaited(
          ChatEventToggleLocalAI().send().then(
            (result) {
              if (!isClosed) {
                add(LocalAIToggleEvent.handleResult(result));
              }
            },
          ),
        );
      },
      handleResult: (result) {
        _handleResult(emit, result);
      },
    );
  }

  void _handleResult(
    Emitter<LocalAIToggleState> emit,
    FlowyResult<LocalAIPB, FlowyError> result,
  ) {
    result.fold(
      (localAI) {
        emit(
          state.copyWith(
            pageIndicator: LocalAIToggleStateIndicator.ready(localAI.enabled),
          ),
        );
      },
      (err) {
        emit(
          state.copyWith(
            pageIndicator: LocalAIToggleStateIndicator.error(err),
          ),
        );
      },
    );
  }
}

@freezed
class LocalAIToggleEvent with _$LocalAIToggleEvent {
  const factory LocalAIToggleEvent.started() = _Started;
  const factory LocalAIToggleEvent.toggle() = _Toggle;
  const factory LocalAIToggleEvent.handleResult(
    FlowyResult<LocalAIPB, FlowyError> result,
  ) = _HandleResult;
}

@freezed
class LocalAIToggleState with _$LocalAIToggleState {
  const factory LocalAIToggleState({
    @Default(LocalAIToggleStateIndicator.loading())
    LocalAIToggleStateIndicator pageIndicator,
  }) = _LocalAIToggleState;
}

@freezed
class LocalAIToggleStateIndicator with _$LocalAIToggleStateIndicator {
  // when start downloading the model
  const factory LocalAIToggleStateIndicator.error(FlowyError error) = _OnError;
  const factory LocalAIToggleStateIndicator.ready(bool isEnabled) = _Ready;
  const factory LocalAIToggleStateIndicator.loading() = _Loading;
}
