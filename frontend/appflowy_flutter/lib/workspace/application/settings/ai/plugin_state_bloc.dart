import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'plugin_state_bloc.freezed.dart';

class PluginStateBloc extends Bloc<PluginStateEvent, PluginState> {
  PluginStateBloc()
      : super(
          const PluginState(runningState: RunningStatePB.Connecting),
        ) {
    on<PluginStateEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    PluginStateEvent event,
    Emitter<PluginState> emit,
  ) async {
    await event.when(
      started: () async {},
    );
  }
}

@freezed
class PluginStateEvent with _$PluginStateEvent {
  const factory PluginStateEvent.started() = _Started;
}

@freezed
class PluginState with _$PluginState {
  const factory PluginState({
    required RunningStatePB runningState,
  }) = _PluginState;
}
