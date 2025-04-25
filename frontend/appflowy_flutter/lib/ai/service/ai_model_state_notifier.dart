import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_model_switch_listener.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:protobuf/protobuf.dart';
import 'package:universal_platform/universal_platform.dart';

typedef OnModelStateChangedCallback = void Function(AIModelState state);
typedef OnAvailableModelsChangedCallback = void Function(
  List<AIModelPB>,
  AIModelPB?,
);

/// Represents the state of an AI model
class AIModelState {
  const AIModelState({
    required this.type,
    required this.hintText,
    required this.tooltip,
    required this.isEditable,
    required this.localAIEnabled,
  });
  final AiType type;

  /// The text displayed as placeholder/hint in the input field
  /// Shows different messages based on AI state (enabled, initializing, disabled)
  final String hintText;

  /// Optional tooltip text that appears on hover
  /// Provides additional context about the current state of the AI
  /// Null when no tooltip should be shown
  final String? tooltip;

  final bool isEditable;
  final bool localAIEnabled;
}

class AIModelStateNotifier {
  AIModelStateNotifier({required this.objectId})
      : _localAIListener =
            UniversalPlatform.isDesktop ? LocalAIStateListener() : null,
        _aiModelSwitchListener = AIModelSwitchListener(objectId: objectId) {
    _startListening();
    _init();
  }

  final String objectId;
  final LocalAIStateListener? _localAIListener;
  final AIModelSwitchListener _aiModelSwitchListener;
  LocalAIPB? _localAIState;
  ModelSelectionPB? _sourceModelSelection;

  // callbacks
  final List<OnModelStateChangedCallback> _stateChangedCallbacks = [];
  final List<OnAvailableModelsChangedCallback>
      _availableModelsChangedCallbacks = [];

  void _startListening() {
    if (UniversalPlatform.isDesktop) {
      _localAIListener?.start(
        stateCallback: (state) async {
          _localAIState = state;
          _notifyStateChanged();

          if (state.state == RunningStatePB.Running ||
              state.state == RunningStatePB.Stopped) {
            await _loadModelSelection();
            _notifyAvailableModelsChanged();
          }
        },
      );
    }

    _aiModelSwitchListener.start(
      onUpdateSelectedModel: (model) async {
        final updatedModels = _sourceModelSelection?.deepCopy()
          ?..selectedModel = model;
        _sourceModelSelection = updatedModels;

        _notifyAvailableModelsChanged();
        if (model.isLocal && UniversalPlatform.isDesktop) {
          await _loadLocalAiState();
        }
        _notifyStateChanged();
      },
    );
  }

  void _init() async {
    await Future.wait([_loadLocalAiState(), _loadModelSelection()]);
    _notifyStateChanged();
    _notifyAvailableModelsChanged();
  }

  void addListener({
    OnModelStateChangedCallback? onStateChanged,
    OnAvailableModelsChangedCallback? onAvailableModelsChanged,
  }) {
    if (onStateChanged != null) {
      _stateChangedCallbacks.add(onStateChanged);
    }
    if (onAvailableModelsChanged != null) {
      _availableModelsChangedCallbacks.add(onAvailableModelsChanged);
    }
  }

  void removeListener({
    OnModelStateChangedCallback? onStateChanged,
    OnAvailableModelsChangedCallback? onAvailableModelsChanged,
  }) {
    if (onStateChanged != null) {
      _stateChangedCallbacks.remove(onStateChanged);
    }
    if (onAvailableModelsChanged != null) {
      _availableModelsChangedCallbacks.remove(onAvailableModelsChanged);
    }
  }

  Future<void> dispose() async {
    _stateChangedCallbacks.clear();
    _availableModelsChangedCallbacks.clear();
    await _localAIListener?.stop();
    await _aiModelSwitchListener.stop();
  }

  AIModelState getState() {
    if (UniversalPlatform.isMobile) {
      return AIModelState(
        type: AiType.cloud,
        hintText: LocaleKeys.chat_inputMessageHint.tr(),
        tooltip: null,
        isEditable: true,
        localAIEnabled: false,
      );
    }

    final availableModels = _sourceModelSelection;
    final localAiState = _localAIState;

    if (availableModels == null) {
      return AIModelState(
        type: AiType.cloud,
        hintText: LocaleKeys.chat_inputMessageHint.tr(),
        isEditable: true,
        tooltip: null,
        localAIEnabled: false,
      );
    }
    if (localAiState == null) {
      return AIModelState(
        type: AiType.cloud,
        hintText: LocaleKeys.chat_inputMessageHint.tr(),
        tooltip: null,
        isEditable: true,
        localAIEnabled: false,
      );
    }

    if (!availableModels.selectedModel.isLocal) {
      return AIModelState(
        type: AiType.cloud,
        hintText: LocaleKeys.chat_inputMessageHint.tr(),
        tooltip: null,
        isEditable: true,
        localAIEnabled: false,
      );
    }

    final editable = localAiState.state == RunningStatePB.Running;
    final tooltip = localAiState.enabled
        ? (editable
            ? null
            : LocaleKeys.settings_aiPage_keys_localAINotReadyTextFieldPrompt
                .tr())
        : LocaleKeys.settings_aiPage_keys_localAIDisabledTextFieldPrompt.tr();

    final hintText = localAiState.enabled
        ? (editable
            ? LocaleKeys.chat_inputLocalAIMessageHint.tr()
            : LocaleKeys.settings_aiPage_keys_localAIInitializing.tr())
        : LocaleKeys.settings_aiPage_keys_localAIDisabled.tr();

    return AIModelState(
      type: AiType.local,
      hintText: hintText,
      tooltip: tooltip,
      isEditable: editable,
      localAIEnabled: localAiState.enabled,
    );
  }

  (List<AIModelPB>, AIModelPB?) getModelSelection() {
    final availableModels = _sourceModelSelection;
    if (availableModels == null) {
      return ([], null);
    }
    return (availableModels.models, availableModels.selectedModel);
  }

  void _notifyAvailableModelsChanged() {
    final (models, selectedModel) = getModelSelection();
    for (final callback in _availableModelsChangedCallbacks) {
      callback(models, selectedModel);
    }
  }

  void _notifyStateChanged() {
    final state = getState();
    for (final callback in _stateChangedCallbacks) {
      callback(state);
    }
  }

  Future<void> _loadModelSelection() {
    final payload = ModelSourcePB(source: objectId);
    return AIEventGetSourceModelSelection(payload).send().fold(
          (models) => _sourceModelSelection = models,
          (err) => Log.error("Failed to get available models: $err"),
        );
  }

  Future<void> _loadLocalAiState() {
    return AIEventGetLocalAIState().send().fold(
          (localAIState) => _localAIState = localAIState,
          (error) => Log.error("Failed to get local AI state: $error"),
        );
  }
}

extension AiModelExtension on AIModelPB {
  bool get isDefault {
    return name == "Auto";
  }

  String get i18n {
    return isDefault ? LocaleKeys.chat_switchModel_autoModel.tr() : name;
  }
}
