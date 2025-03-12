import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_ai_setting_panel_bloc.freezed.dart';

class LocalAISettingPanelBloc
    extends Bloc<LocalAISettingPanelEvent, LocalAISettingPanelState> {
  LocalAISettingPanelBloc()
      : listener = LocalAIStateListener(),
        super(const LocalAISettingPanelState()) {
    on<LocalAISettingPanelEvent>(_handleEvent);

    listener.start(
      stateCallback: (newState) {
        if (!isClosed) {
          add(LocalAISettingPanelEvent.updateAIState(newState));
        }
      },
    );

    AIEventGetLocalAIState().send().fold(
      (localAIState) {
        if (!isClosed) {
          add(LocalAISettingPanelEvent.updateAIState(localAIState));
        }
      },
      Log.error,
    );
  }

  final LocalAIStateListener listener;

  /// Handles incoming events and dispatches them to the appropriate handler.
  Future<void> _handleEvent(
    LocalAISettingPanelEvent event,
    Emitter<LocalAISettingPanelState> emit,
  ) async {
    event.when(
      updateAIState: (LocalAIPB pluginState) {
        if (pluginState.isPluginExecutableReady) {
          emit(
            state.copyWith(
              runningState: pluginState.state,
              progressIndicator: const LocalAIProgress.checkPluginState(),
            ),
          );
        } else {
          emit(
            state.copyWith(
              progressIndicator: const LocalAIProgress.downloadLocalAIApp(),
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class LocalAISettingPanelEvent with _$LocalAISettingPanelEvent {
  const factory LocalAISettingPanelEvent.updateAIState(
    LocalAIPB aiState,
  ) = _UpdateAIState;
}

@freezed
class LocalAISettingPanelState with _$LocalAISettingPanelState {
  const factory LocalAISettingPanelState({
    LocalAIProgress? progressIndicator,
    @Default(RunningStatePB.Connecting) RunningStatePB runningState,
  }) = _LocalAIChatSettingState;
}

@freezed
class LocalAIProgress with _$LocalAIProgress {
  const factory LocalAIProgress.checkPluginState() = _CheckPluginStateProgress;
  const factory LocalAIProgress.downloadLocalAIApp() =
      _DownloadLocalAIAppProgress;
}
