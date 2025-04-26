import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_model_switch_listener.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
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
  ModelSelectionPB? _modelSelection;

  AIModelState _currentState = _defaultState();
  List<AIModelPB> _availableModels = [];
  AIModelPB? _selectedModel;

  final List<OnModelStateChangedCallback> _stateChangedCallbacks = [];
  final List<OnAvailableModelsChangedCallback>
      _availableModelsChangedCallbacks = [];

  /// Starts platform-specific listeners
  void _startListening() {
    if (UniversalPlatform.isDesktop) {
      _localAIListener?.start(
        stateCallback: (state) async {
          _localAIState = state;
          _updateAll();
          if (state.state == RunningStatePB.Running ||
              state.state == RunningStatePB.Stopped) {
            await _loadModelSelection();
            _updateAll();
          }
        },
      );
    }

    _aiModelSwitchListener.start(
      onUpdateSelectedModel: (model) async {
        _selectedModel = model;
        _updateAll();
        if (model.isLocal && UniversalPlatform.isDesktop) {
          await _loadLocalState();
          _updateAll();
        }
      },
    );
  }

  Future<void> _init() async {
    await Future.wait([
      if (UniversalPlatform.isDesktop) _loadLocalState(),
      _loadModelSelection(),
    ]);
    _updateAll();
  }

  /// Register callbacks for state or available-models changes
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

  /// Remove previously registered callbacks
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

  /// Returns current AIModelState
  AIModelState getState() => _currentState;

  /// Returns available models and the selected model
  (List<AIModelPB>, AIModelPB?) getModelSelection() =>
      (_availableModels, _selectedModel);

  void _updateAll() {
    _currentState = _computeState();
    for (final cb in _stateChangedCallbacks) {
      cb(_currentState);
    }
    for (final cb in _availableModelsChangedCallbacks) {
      cb(_availableModels, _selectedModel);
    }
  }

  Future<void> _loadModelSelection() async {
    await AIEventGetSourceModelSelection(
      ModelSourcePB(source: objectId),
    ).send().fold(
      (ms) {
        _modelSelection = ms;
        _availableModels = ms.models;
        _selectedModel = ms.selectedModel;
      },
      (e) => Log.error("Failed to fetch models: \$e"),
    );
  }

  Future<void> _loadLocalState() async {
    await AIEventGetLocalAIState().send().fold(
          (s) => _localAIState = s,
          (e) => Log.error("Failed to fetch local AI state: \$e"),
        );
  }

  static AIModelState _defaultState() => AIModelState(
        type: AiType.cloud,
        hintText: LocaleKeys.chat_inputMessageHint.tr(),
        tooltip: null,
        isEditable: true,
        localAIEnabled: false,
      );

  /// Core logic computing the state from local and selection data
  AIModelState _computeState() {
    if (UniversalPlatform.isMobile) return _defaultState();

    if (_modelSelection == null || _localAIState == null) {
      return _defaultState();
    }

    if (!_selectedModel!.isLocal) {
      return _defaultState();
    }

    final enabled = _localAIState!.enabled;
    final running = _localAIState!.state == RunningStatePB.Running;
    final hintKey = enabled
        ? (running
            ? LocaleKeys.chat_inputLocalAIMessageHint
            : LocaleKeys.settings_aiPage_keys_localAIInitializing)
        : LocaleKeys.settings_aiPage_keys_localAIDisabled;
    final tooltipKey = enabled
        ? (running
            ? null
            : LocaleKeys.settings_aiPage_keys_localAINotReadyTextFieldPrompt)
        : LocaleKeys.settings_aiPage_keys_localAIDisabledTextFieldPrompt;

    return AIModelState(
      type: AiType.local,
      hintText: hintKey.tr(),
      tooltip: tooltipKey?.tr(),
      isEditable: running,
      localAIEnabled: enabled,
    );
  }
}

extension AIModelPBExtension on AIModelPB {
  bool get isDefault => name == 'Auto';
  String get i18n =>
      isDefault ? LocaleKeys.chat_switchModel_autoModel.tr() : name;
}
