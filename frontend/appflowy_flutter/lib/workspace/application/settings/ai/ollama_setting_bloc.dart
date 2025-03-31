import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'ollama_setting_bloc.freezed.dart';

class OllamaSettingBloc extends Bloc<OllamaSettingEvent, OllamaSettingState> {
  OllamaSettingBloc() : super(const OllamaSettingState()) {
    on<OllamaSettingEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    OllamaSettingEvent event,
    Emitter<OllamaSettingState> emit,
  ) async {
    event.when(
      started: () {
        AIEventGetLocalAISetting().send().fold(
          (setting) {
            if (!isClosed) {
              add(OllamaSettingEvent.didLoadSetting(setting));
            }
          },
          Log.error,
        );
      },
      didLoadSetting: (setting) => _updateSetting(setting, emit),
      updateSetting: (setting) => _updateSetting(setting, emit),
      onEdit: (content, settingType) {
        final updatedSubmittedItems = state.submittedItems
            .map(
              (item) => item.settingType == settingType
                  ? SubmittedItem(
                      content: content,
                      settingType: item.settingType,
                    )
                  : item,
            )
            .toList();

        // Convert both lists to maps: {settingType: content}
        final updatedMap = {
          for (final item in updatedSubmittedItems)
            item.settingType: item.content,
        };

        final inputMap = {
          for (final item in state.inputItems) item.settingType: item.content,
        };

        // Compare maps instead of lists
        final isEdited = !const MapEquality<SettingType, String>()
            .equals(updatedMap, inputMap);

        emit(
          state.copyWith(
            submittedItems: updatedSubmittedItems,
            isEdited: isEdited,
          ),
        );
      },
      submit: () {
        final setting = LocalAISettingPB();
        final settingUpdaters = <SettingType, void Function(String)>{
          SettingType.serverUrl: (value) => setting.serverUrl = value,
          SettingType.chatModel: (value) => setting.chatModelName = value,
          SettingType.embeddingModel: (value) =>
              setting.embeddingModelName = value,
        };

        for (final item in state.submittedItems) {
          settingUpdaters[item.settingType]?.call(item.content);
        }
        add(OllamaSettingEvent.updateSetting(setting));
        AIEventUpdateLocalAISetting(setting).send().fold(
              (_) => Log.info('AI setting updated successfully'),
              (err) => Log.error("update ai setting failed: $err"),
            );
      },
    );
  }

  void _updateSetting(
    LocalAISettingPB setting,
    Emitter<OllamaSettingState> emit,
  ) {
    emit(
      state.copyWith(
        setting: setting,
        inputItems: _createInputItems(setting),
        submittedItems: _createSubmittedItems(setting),
        isEdited: false, // Reset to false when the setting is loaded/updated.
      ),
    );
  }

  List<SettingItem> _createInputItems(LocalAISettingPB setting) => [
        SettingItem(
          content: setting.serverUrl,
          hintText: 'http://localhost:11434',
          settingType: SettingType.serverUrl,
        ),
        SettingItem(
          content: setting.chatModelName,
          hintText: 'llama3.1',
          settingType: SettingType.chatModel,
        ),
        SettingItem(
          content: setting.embeddingModelName,
          hintText: 'nomic-embed-text',
          settingType: SettingType.embeddingModel,
        ),
      ];

  List<SubmittedItem> _createSubmittedItems(LocalAISettingPB setting) => [
        SubmittedItem(
          content: setting.serverUrl,
          settingType: SettingType.serverUrl,
        ),
        SubmittedItem(
          content: setting.chatModelName,
          settingType: SettingType.chatModel,
        ),
        SubmittedItem(
          content: setting.embeddingModelName,
          settingType: SettingType.embeddingModel,
        ),
      ];
}

// Create an enum for setting type.
enum SettingType {
  serverUrl,
  chatModel,
  embeddingModel; // semicolon needed after the enum values

  String get title {
    switch (this) {
      case SettingType.serverUrl:
        return 'Ollama server url';
      case SettingType.chatModel:
        return 'Chat model name';
      case SettingType.embeddingModel:
        return 'Embedding model name';
    }
  }
}

class SettingItem extends Equatable {
  const SettingItem({
    required this.content,
    required this.hintText,
    required this.settingType,
  });
  final String content;
  final String hintText;
  final SettingType settingType;
  @override
  List<Object?> get props => [content, settingType];
}

class SubmittedItem extends Equatable {
  const SubmittedItem({
    required this.content,
    required this.settingType,
  });
  final String content;
  final SettingType settingType;

  @override
  List<Object?> get props => [content, settingType];
}

@freezed
class OllamaSettingEvent with _$OllamaSettingEvent {
  const factory OllamaSettingEvent.started() = _Started;
  const factory OllamaSettingEvent.didLoadSetting(LocalAISettingPB setting) =
      _DidLoadSetting;
  const factory OllamaSettingEvent.updateSetting(LocalAISettingPB setting) =
      _UpdateSetting;
  const factory OllamaSettingEvent.onEdit(
    String content,
    SettingType settingType,
  ) = _OnEdit;
  const factory OllamaSettingEvent.submit() = _OnSubmit;
}

@freezed
class OllamaSettingState with _$OllamaSettingState {
  const factory OllamaSettingState({
    LocalAISettingPB? setting,
    @Default([
      SettingItem(
        content: 'http://localhost:11434',
        hintText: 'http://localhost:11434',
        settingType: SettingType.serverUrl,
      ),
      SettingItem(
        content: 'llama3.1',
        hintText: 'llama3.1',
        settingType: SettingType.chatModel,
      ),
      SettingItem(
        content: 'nomic-embed-text',
        hintText: 'nomic-embed-text',
        settingType: SettingType.embeddingModel,
      ),
    ])
    List<SettingItem> inputItems,
    @Default([]) List<SubmittedItem> submittedItems,
    @Default(false) bool isEdited,
  }) = _PluginStateState;
}
