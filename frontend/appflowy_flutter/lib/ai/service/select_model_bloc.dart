import 'dart:async';

import 'package:appflowy/ai/service/ai_model_state_notifier.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbserver.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_model_bloc.freezed.dart';

class AiModel extends Equatable {
  const AiModel({
    required this.name,
    required this.isLocal,
  });

  factory AiModel.fromPB(AIModelPB pb) {
    return AiModel(name: pb.name, isLocal: pb.isLocal);
  }

  AIModelPB toPB() {
    return AIModelPB()
      ..name = name
      ..isLocal = isLocal;
  }

  final String name;
  final bool isLocal;

  @override
  List<Object?> get props => [name, isLocal];
}

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
                selectedModel: model.toPB(),
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

  void _onAvailableModelsChanged(List<AiModel> models, AiModel? selectedModel) {
    if (!isClosed) {
      add(SelectModelEvent.didLoadModels(models, selectedModel));
    }
  }
}

@freezed
class SelectModelEvent with _$SelectModelEvent {
  const factory SelectModelEvent.selectModel(
    AiModel model,
  ) = _SelectModel;

  const factory SelectModelEvent.didLoadModels(
    List<AiModel> models,
    AiModel? selectedModel,
  ) = _DidLoadModels;
}

@freezed
class SelectModelState with _$SelectModelState {
  const factory SelectModelState({
    required List<AiModel> models,
    required AiModel? selectedModel,
  }) = _SelectModelState;

  factory SelectModelState.initial(AIModelStateNotifier notifier) {
    final (models, selectedModel) = notifier.getAvailableModels();
    return SelectModelState(
      models: models,
      selectedModel: selectedModel,
    );
  }
}
