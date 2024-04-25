import 'dart:async';

import 'package:appflowy/shared/local_ai_server.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ai_bloc.freezed.dart';

class SettingsAIBloc extends Bloc<SettingsAIEvent, SettingsAIState> {
  SettingsAIBloc() : super(SettingsAIState.initial()) {
    on<SettingsAIEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        setLocalLLMPath: (path) async {
          await setLocalLLMPath(emit, path);
        },
        updateLocalServerHealth: (result) async {
          emit(
            state.copyWith(
              actionResult: result,
            ),
          );
        },
      );
    });
  }

  final aiServer = LocalAIServer();
  final host = '127.0.0.1';
  int? port;
  Timer? timer;

  @override
  Future<void> close() async {
    timer?.cancel();
    await super.close();
  }

  Future<void> setLocalLLMPath(Emitter emit, String path) async {
    // load the local model
    emit(
      state.copyWith(
        actionResult: const SettingsAIRequestResult(
          actionType: SettingsAILLMMode.local,
          isLoading: true,
          result: null,
        ),
      ),
    );
    final launchResult = await LocalAIServer().launch(
      localLLMPath: path,
      host: host,
    );
    final isLoadSuccess = launchResult.$1;
    port = launchResult.$2;
    debugPrint('Local LLM launched at localhost:$port');
    if (!isLoadSuccess) {
      // only update the state if the load failed
      emit(
        state.copyWith(
          actionResult: SettingsAIRequestResult(
            actionType: SettingsAILLMMode.local,
            isLoading: false,
            result: FlowyResult.failure(
              FlowyError(msg: 'Load Local LLM Failed'),
            ),
          ),
        ),
      );
    } else {
      observeLocalServeHealth();
    }
  }

  void observeLocalServeHealth() {
    if (port == null) {
      return;
    }
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final result = await aiServer.pingServer(host, port!);
      debugPrint('Local server health: $result');
      final requestResult = SettingsAIRequestResult(
        actionType: SettingsAILLMMode.local,
        isLoading: false,
        result: result,
      );
      add(SettingsAIEvent.updateLocalServerHealth(requestResult));
    });
  }
}

@freezed
class SettingsAIEvent with _$SettingsAIEvent {
  const factory SettingsAIEvent.initial() = Initial;
  const factory SettingsAIEvent.setLocalLLMPath(String localLLMPath) =
      SetLocalLLMPath;
  const factory SettingsAIEvent.updateLocalServerHealth(
    SettingsAIRequestResult result,
  ) = UpdateLocalServerHealth;
}

enum SettingsAILLMMode {
  none,
  local,
  remote,
}

class SettingsAIRequestResult {
  const SettingsAIRequestResult({
    required this.actionType,
    required this.isLoading,
    required this.result,
  });

  final SettingsAILLMMode actionType;
  final bool isLoading;
  final FlowyResult<void, FlowyError>? result;
}

@freezed
class SettingsAIState with _$SettingsAIState {
  const SettingsAIState._();

  const factory SettingsAIState({
    @Default(SettingsAILLMMode.local) SettingsAILLMMode mode,
    @Default(null) SettingsAIRequestResult? actionResult,
    String? localLLMPath,
  }) = _SettingsAIState;

  factory SettingsAIState.initial() => const SettingsAIState();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsAIState &&
        other.mode == mode &&
        identical(other.actionResult, actionResult);
  }
}
