import 'package:appflowy/ai/service/ai_prompt_input_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_model_switch_listener.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:protobuf/protobuf.dart';
import 'package:universal_platform/universal_platform.dart';

class AIModelStateNotifier {
  AIModelStateNotifier({required this.objectId})
      : _isDesktop = UniversalPlatform.isDesktop,
        _localAIListener =
            UniversalPlatform.isDesktop ? LocalAIStateListener() : null,
        _aiModelSwitchListener = AIModelSwitchListener(chatId: objectId);

  final String objectId;
  final bool _isDesktop;
  final LocalAIStateListener? _localAIListener;
  final AIModelSwitchListener _aiModelSwitchListener;

  LocalAIPB? _localAIState;
  AvailableModelsPB? _availableModels;

  // Callbacks
  void Function(AiType, bool, String)? onChanged;
  void Function(AvailableModelsPB)? onAvailableModelsChanged;

  String hintText() {
    final aiType = getCurrentAiType();
    if (aiType.isLocal) {
      return isEditable()
          ? LocaleKeys.chat_inputLocalAIMessageHint.tr()
          : LocaleKeys.settings_aiPage_keys_localAIInitializing.tr();
    }
    return LocaleKeys.chat_inputMessageHint.tr();
  }

  AiType getCurrentAiType() {
    // On non-desktop platforms, always return cloud type.
    if (!_isDesktop) return AiType.cloud;
    return (_availableModels?.selectedModel.isLocal ?? false)
        ? AiType.local
        : AiType.cloud;
  }

  bool isEditable() {
    // On non-desktop platforms, always editable.
    if (!_isDesktop) return true;
    return getCurrentAiType().isLocal
        ? _localAIState?.state == RunningStatePB.Running
        : true;
  }

  void _notifyStateChanged() {
    onChanged?.call(getCurrentAiType(), isEditable(), hintText());
  }

  Future<void> init() async {
    // Load both available models and local state concurrently.
    await Future.wait([
      _loadAvailableModels(),
      _loadLocalAIState(),
    ]);
  }

  Future<void> _loadAvailableModels() async {
    final payload = AvailableModelsQueryPB(source: objectId);
    final result = await AIEventGetAvailableModels(payload).send();
    result.fold(
      (models) {
        _availableModels = models;
        onAvailableModelsChanged?.call(models);
        _notifyStateChanged();
      },
      (err) => Log.error("Failed to get available models: $err"),
    );
  }

  Future<void> _loadLocalAIState() async {
    final result = await AIEventGetLocalAIState().send();
    result.fold(
      (state) {
        _localAIState = state;
        _notifyStateChanged();
      },
      (error) {
        Log.error("Failed to get local AI state: $error");
        _notifyStateChanged();
      },
    );
  }

  void startListening({
    void Function(AiType, bool, String)? onChanged,
    void Function(AvailableModelsPB)? onAvailableModelsChanged,
  }) {
    this.onChanged = onChanged;
    this.onAvailableModelsChanged = onAvailableModelsChanged;

    // Only start local AI listener on desktop platforms.
    if (_isDesktop) {
      _localAIListener?.start(
        stateCallback: (state) {
          _localAIState = state;
          if (state.state == RunningStatePB.Running ||
              state.state == RunningStatePB.Stopped) {
            _loadAvailableModels();
          }
        },
      );
    }

    _aiModelSwitchListener.start(
      onUpdateSelectedModel: (model) {
        if (_availableModels != null) {
          final updatedModels = _availableModels!.deepCopy()
            ..selectedModel = model;
          _availableModels = updatedModels;
          onAvailableModelsChanged?.call(updatedModels);
        }
        if (model.isLocal && _isDesktop) {
          _loadLocalAIState();
        } else {
          _notifyStateChanged();
        }
      },
    );
  }

  Future<void> stop() async {
    onChanged = null;
    await _localAIListener?.stop();
    await _aiModelSwitchListener.stop();
  }
}
