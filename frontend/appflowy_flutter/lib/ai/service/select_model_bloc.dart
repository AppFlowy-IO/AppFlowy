import 'dart:async';

import 'package:appflowy/ai/service/ai_model_state_notifier.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_model_bloc.freezed.dart';

class SelectModelBloc extends Bloc<SelectModelEvent, SelectModelState> {
  SelectModelBloc({
    required AIModelStateNotifier aiModelStateNotifier,
  })  : _aiModelStateNotifier = aiModelStateNotifier,
        super(SelectModelState.initial(aiModelStateNotifier)) {
    on<SelectModelEvent>(
      (event, emit) {
        event.when(
          selectModel: (model) {
            AIEventUpdateSelectedModel(
              UpdateSelectedModelPB(
                source: _aiModelStateNotifier.objectId,
                selectedModel: model,
              ),
            ).send();

            emit(state.copyWith(selectedModel: model));
          },
          didLoadModels: (models, selectedModel) {
            emit(
              SelectModelState(
                models: models,
                selectedModel: selectedModel,
              ),
            );
          },
        );
      },
    );

    _aiModelStateNotifier.addListener(
      onAvailableModelsChanged: _onAvailableModelsChanged,
    );
  }

  final AIModelStateNotifier _aiModelStateNotifier;

  @override
  Future<void> close() async {
    _aiModelStateNotifier.removeListener(
      onAvailableModelsChanged: _onAvailableModelsChanged,
    );
    await super.close();
  }

  void _onAvailableModelsChanged(
    List<AIModelPB> models,
    AIModelPB? selectedModel,
  ) {
    if (!isClosed) {
      add(SelectModelEvent.didLoadModels(models, selectedModel));
    }
  }
}

@freezed
class SelectModelEvent with _$SelectModelEvent {
  const factory SelectModelEvent.selectModel(
    AIModelPB model,
  ) = _SelectModel;

  const factory SelectModelEvent.didLoadModels(
    List<AIModelPB> models,
    AIModelPB? selectedModel,
  ) = _DidLoadModels;
}

@freezed
class SelectModelState with _$SelectModelState {
  const factory SelectModelState({
    required List<AIModelPB> models,
    required AIModelPB? selectedModel,
  }) = _SelectModelState;

  factory SelectModelState.initial(AIModelStateNotifier notifier) {
    final (models, selectedModel) = notifier.getModelSelection();
    return SelectModelState(
      models: models,
      selectedModel: selectedModel,
    );
  }
}
