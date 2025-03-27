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

typedef OnModelStateChangedCallback = void Function(AiType, bool, String);
typedef OnAvailableModelsChangedCallback = void Function(
  List<AIModelPB>,
  AIModelPB?,
);

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
  AvailableModelsPB? _availableModels;

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
            await _loadAvailableModels();
            _notifyAvailableModelsChanged();
          }
        },
      );
    }

    _aiModelSwitchListener.start(
      onUpdateSelectedModel: (model) async {
        final updatedModels = _availableModels?.deepCopy()
          ?..selectedModel = model;
        _availableModels = updatedModels;
        _notifyAvailableModelsChanged();

        if (model.isLocal && UniversalPlatform.isDesktop) {
          await _loadLocalAiState();
        }
        _notifyStateChanged();
      },
    );
  }

  void _init() async {
    await Future.wait([_loadLocalAiState(), _loadAvailableModels()]);
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

  (AiType, String, bool) getState() {
    if (UniversalPlatform.isMobile) {
      return (AiType.cloud, LocaleKeys.chat_inputMessageHint.tr(), true);
    }

    final availableModels = _availableModels;
    final localAiState = _localAIState;

    if (availableModels == null) {
      Log.warn("No available models");
      return (AiType.cloud, LocaleKeys.chat_inputMessageHint.tr(), true);
    }
    if (localAiState == null) {
      Log.warn("Cannot get local AI state");
      return (AiType.cloud, LocaleKeys.chat_inputMessageHint.tr(), true);
    }

    if (!availableModels.selectedModel.isLocal) {
      return (AiType.cloud, LocaleKeys.chat_inputMessageHint.tr(), true);
    }

    final editable = localAiState.state == RunningStatePB.Running;
    final hintText = editable
        ? LocaleKeys.chat_inputLocalAIMessageHint.tr()
        : LocaleKeys.settings_aiPage_keys_localAIInitializing.tr();

    return (AiType.local, hintText, editable);
  }

  (List<AIModelPB>, AIModelPB?) getAvailableModels() {
    final availableModels = _availableModels;
    if (availableModels == null) {
      return ([], null);
    }
    return (availableModels.models, availableModels.selectedModel);
  }

  void _notifyAvailableModelsChanged() {
    final (models, selectedModel) = getAvailableModels();
    for (final callback in _availableModelsChangedCallbacks) {
      callback(models, selectedModel);
    }
  }

  void _notifyStateChanged() {
    final (type, hintText, isEditable) = getState();
    for (final callback in _stateChangedCallbacks) {
      callback(type, isEditable, hintText);
    }
  }

  Future<void> _loadAvailableModels() {
    final payload = AvailableModelsQueryPB(source: objectId);
    return AIEventGetAvailableModels(payload).send().fold(
          (models) => _availableModels = models,
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
