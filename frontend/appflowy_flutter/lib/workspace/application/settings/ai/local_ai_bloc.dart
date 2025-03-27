import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'local_ai_bloc.freezed.dart';

class LocalAIToggleBloc extends Bloc<LocalAIToggleEvent, LocalAiToggleState> {
  LocalAIToggleBloc() : super(const LoadingLocalAiToggleState()) {
    on<LocalAIToggleEvent>(_handleEvent);
    _getLocalAiState();
  }

  Future<void> _handleEvent(
    LocalAIToggleEvent event,
    Emitter<LocalAiToggleState> emit,
  ) async {
    await event.when(
      toggle: () async {
        emit(LoadingLocalAiToggleState());
        final result = await AIEventToggleLocalAI().send();
        add(LocalAIToggleEvent.handleResult(result));
      },
      handleResult: (result) {
        _handleResult(emit, result);
      },
    );
  }

  void _handleResult(
    Emitter<LocalAiToggleState> emit,
    FlowyResult<LocalAIPB, FlowyError> result,
  ) {
    result.fold(
      (localAI) => emit(ReadyLocalAiToggleState(isEnabled: localAI.enabled)),
      (err) => emit(ErrorLocalAiToggleState(error: err)),
    );
  }

  void _getLocalAiState() async {
    final result = await AIEventGetLocalAIState().send();
    add(LocalAIToggleEvent.handleResult(result));
  }
}

@freezed
class LocalAIToggleEvent with _$LocalAIToggleEvent {
  const factory LocalAIToggleEvent.toggle() = _Toggle;
  const factory LocalAIToggleEvent.handleResult(
    FlowyResult<LocalAIPB, FlowyError> result,
  ) = _HandleResult;
}

sealed class LocalAiToggleState {
  const LocalAiToggleState();
}

class ReadyLocalAiToggleState extends LocalAiToggleState {
  const ReadyLocalAiToggleState({
    required this.isEnabled,
  });

  final bool isEnabled;
}

class LoadingLocalAiToggleState extends LocalAiToggleState {
  const LoadingLocalAiToggleState();
}

class ErrorLocalAiToggleState extends LocalAiToggleState {
  const ErrorLocalAiToggleState({
    required this.error,
  });

  final FlowyError error;
}
