import 'dart:async';

import 'package:appflowy/ai/service/ai_input_control.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'select_model_bloc.freezed.dart';

class SelectModelBloc extends Bloc<SelectModelEvent, SelectModelState> {
  SelectModelBloc({
    required this.objectId,
  })  : _aiModelStateNotifier = AIModelStateNotifier(objectId: objectId),
        super(const SelectModelState()) {
    _aiModelStateNotifier.init();
    _aiModelStateNotifier.startListening(
      onAvailableModelsChanged: (models) {
        if (!isClosed) {
          add(SelectModelEvent.didLoadModels(models));
        }
      },
    );

    on<SelectModelEvent>(
      (event, emit) async {
        await event.when(
          selectModel: (AIModelPB model) async {
            await AIEventUpdateSelectedModel(
              UpdateSelectedModelPB(
                source: objectId,
                selectedModel: model,
              ),
            ).send();

            state.availableModels?.freeze();
            final newAvailableModels = state.availableModels?.rebuild((m) {
              m.selectedModel = model;
            });

            emit(
              state.copyWith(
                availableModels: newAvailableModels,
              ),
            );
          },
          didLoadModels: (AvailableModelsPB models) {
            emit(state.copyWith(availableModels: models));
          },
        );
      },
    );
  }

  final String objectId;
  final AIModelStateNotifier _aiModelStateNotifier;

  @override
  Future<void> close() async {
    await _aiModelStateNotifier.stop();
    await super.close();
  }
}

@freezed
class SelectModelEvent with _$SelectModelEvent {
  const factory SelectModelEvent.selectModel(
    AIModelPB model,
  ) = _SelectModel;

  const factory SelectModelEvent.didLoadModels(
    AvailableModelsPB models,
  ) = _DidLoadModels;
}

@freezed
class SelectModelState with _$SelectModelState {
  const factory SelectModelState({
    AvailableModelsPB? availableModels,
  }) = _SelectModelState;
}
