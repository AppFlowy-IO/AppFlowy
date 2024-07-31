import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'local_ai_chat_toggle_bloc.freezed.dart';

class LocalAIChatToggleBloc
    extends Bloc<LocalAIChatToggleEvent, LocalAIChatToggleState> {
  LocalAIChatToggleBloc() : super(const LocalAIChatToggleState()) {
    on<LocalAIChatToggleEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    LocalAIChatToggleEvent event,
    Emitter<LocalAIChatToggleState> emit,
  ) async {
    await event.when(
      started: () async {
        final result = await ChatEventGetLocalAIChatState().send();
        _handleResult(emit, result);
      },
      toggle: () async {
        emit(
          state.copyWith(
            pageIndicator: const LocalAIChatToggleStateIndicator.loading(),
          ),
        );
        unawaited(
          ChatEventToggleLocalAIChat().send().then(
            (result) {
              if (!isClosed) {
                add(LocalAIChatToggleEvent.handleResult(result));
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
    Emitter<LocalAIChatToggleState> emit,
    FlowyResult<LocalAIChatPB, FlowyError> result,
  ) {
    result.fold(
      (localAI) {
        emit(
          state.copyWith(
            pageIndicator:
                LocalAIChatToggleStateIndicator.ready(localAI.enabled),
          ),
        );
      },
      (err) {
        emit(
          state.copyWith(
            pageIndicator: LocalAIChatToggleStateIndicator.error(err),
          ),
        );
      },
    );
  }
}

@freezed
class LocalAIChatToggleEvent with _$LocalAIChatToggleEvent {
  const factory LocalAIChatToggleEvent.started() = _Started;
  const factory LocalAIChatToggleEvent.toggle() = _Toggle;
  const factory LocalAIChatToggleEvent.handleResult(
    FlowyResult<LocalAIChatPB, FlowyError> result,
  ) = _HandleResult;
}

@freezed
class LocalAIChatToggleState with _$LocalAIChatToggleState {
  const factory LocalAIChatToggleState({
    @Default(LocalAIChatToggleStateIndicator.loading())
    LocalAIChatToggleStateIndicator pageIndicator,
  }) = _LocalAIChatToggleState;
}

@freezed
class LocalAIChatToggleStateIndicator with _$LocalAIChatToggleStateIndicator {
  const factory LocalAIChatToggleStateIndicator.error(FlowyError error) =
      _OnError;
  const factory LocalAIChatToggleStateIndicator.ready(bool isEnabled) = _Ready;
  const factory LocalAIChatToggleStateIndicator.loading() = _Loading;
}
