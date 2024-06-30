import 'dart:io';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:protobuf/protobuf.dart';

part 'setting_local_ai_bloc.freezed.dart';

class SettingsAILocalBloc
    extends Bloc<SettingsAILocalEvent, SettingsAILocalState> {
  SettingsAILocalBloc() : super(const SettingsAILocalState()) {
    on<SettingsAILocalEvent>(_handleEvent);
  }

  /// Handles incoming events and dispatches them to the appropriate handler.
  Future<void> _handleEvent(
    SettingsAILocalEvent event,
    Emitter<SettingsAILocalState> emit,
  ) async {
    await event.when(
      started: _handleStarted,
      didUpdateAISetting: (settings) async {
        _handleDidUpdateAISetting(settings, emit);
      },
      updateChatBin: (chatBinPath) async {
        await _handleUpdatePath(
          filePath: chatBinPath,
          emit: emit,
          stateUpdater: () => state.copyWith(
            chatBinPath: chatBinPath.trim(),
            chatBinPathError: null,
          ),
          errorUpdater: (error) => state.copyWith(chatBinPathError: error),
        );
      },
      updateChatModelPath: (chatModelPath) async {
        await _handleUpdatePath(
          filePath: chatModelPath,
          emit: emit,
          stateUpdater: () => state.copyWith(
            chatModelPath: chatModelPath.trim(),
            chatModelPathError: null,
          ),
          errorUpdater: (error) => state.copyWith(chatModelPathError: error),
        );
      },
      toggleLocalAI: () async {
        emit(state.copyWith(localAIEnabled: !state.localAIEnabled));
      },
      saveSetting: () async {
        _handleSaveSetting();
      },
    );
  }

  /// Handles the event to fetch local AI settings when the application starts.
  Future<void> _handleStarted() async {
    final result = await ChatEventGetLocalAISetting().send();
    result.fold(
      (setting) {
        if (!isClosed) {
          add(SettingsAILocalEvent.didUpdateAISetting(setting));
        }
      },
      (err) => Log.error('Failed to get local AI setting: $err'),
    );
  }

  /// Handles the event to update the AI settings in the state.
  void _handleDidUpdateAISetting(
    LocalLLMSettingPB settings,
    Emitter<SettingsAILocalState> emit,
  ) {
    final newState = state.copyWith(
      aiSettings: settings,
      chatBinPath: settings.chatBinPath,
      chatModelPath: settings.chatModelPath,
      localAIEnabled: settings.enabled,
      loadingState: const LoadingState.finish(),
    );
    emit(newState.copyWith(saveButtonEnabled: _saveButtonEnabled(newState)));
  }

  /// Handles updating file paths (both chat binary and chat model paths).
  Future<void> _handleUpdatePath({
    required String filePath,
    required Emitter<SettingsAILocalState> emit,
    required SettingsAILocalState Function() stateUpdater,
    required SettingsAILocalState Function(String) errorUpdater,
  }) async {
    filePath = filePath.trim();
    if (filePath.isEmpty) {
      emit(stateUpdater());
      return;
    }

    final validationError = await _validatePath(filePath);
    if (validationError != null) {
      emit(errorUpdater(validationError));
      return;
    }

    final newState = stateUpdater();
    emit(newState.copyWith(saveButtonEnabled: _saveButtonEnabled(newState)));
  }

  /// Validates the provided file path.
  Future<String?> _validatePath(String filePath) async {
    if (!isAbsolutePath(filePath)) {
      return "$filePath must be absolute";
    }

    if (!await pathExists(filePath)) {
      return "$filePath does not exist";
    }
    return null;
  }

  /// Handles saving the updated settings.
  void _handleSaveSetting() {
    if (state.aiSettings == null) return;
    state.aiSettings!.freeze();
    final newSetting = state.aiSettings!.rebuild((value) {
      value
        ..chatBinPath = state.chatBinPath ?? value.chatBinPath
        ..chatModelPath = state.chatModelPath ?? value.chatModelPath
        ..enabled = state.localAIEnabled;
    });

    ChatEventUpdateLocalAISetting(newSetting).send().then((result) {
      result.fold(
        (_) {
          if (!isClosed) {
            add(SettingsAILocalEvent.didUpdateAISetting(newSetting));
          }
        },
        (err) => Log.error('Failed to update local AI setting: $err'),
      );
    });
  }

  /// Determines if the save button should be enabled based on the state.
  bool _saveButtonEnabled(SettingsAILocalState newState) {
    return newState.chatBinPathError == null &&
        newState.chatModelPathError == null &&
        newState.chatBinPath != null &&
        newState.chatModelPath != null;
  }
}

@freezed
class SettingsAILocalEvent with _$SettingsAILocalEvent {
  const factory SettingsAILocalEvent.started() = _Started;
  const factory SettingsAILocalEvent.didUpdateAISetting(
    LocalLLMSettingPB settings,
  ) = _GetAISetting;
  const factory SettingsAILocalEvent.updateChatBin(String chatBinPath) =
      _UpdateChatBin;
  const factory SettingsAILocalEvent.updateChatModelPath(String chatModelPath) =
      _UpdateChatModelPath;
  const factory SettingsAILocalEvent.toggleLocalAI() = _EnableLocalAI;
  const factory SettingsAILocalEvent.saveSetting() = _SaveSetting;
}

@freezed
class SettingsAILocalState with _$SettingsAILocalState {
  const factory SettingsAILocalState({
    LocalLLMSettingPB? aiSettings,
    String? chatBinPath,
    String? chatBinPathError,
    String? chatModelPath,
    String? chatModelPathError,
    @Default(false) bool localAIEnabled,
    @Default(false) bool saveButtonEnabled,
    @Default(LoadingState.loading()) LoadingState loadingState,
  }) = _SettingsAILocalState;
}

/// Checks if a given file path is absolute.
bool isAbsolutePath(String filePath) {
  return path.isAbsolute(filePath);
}

/// Checks if a given file or directory path exists.
Future<bool> pathExists(String filePath) async {
  final file = File(filePath);
  final directory = Directory(filePath);

  return await file.exists() || await directory.exists();
}
