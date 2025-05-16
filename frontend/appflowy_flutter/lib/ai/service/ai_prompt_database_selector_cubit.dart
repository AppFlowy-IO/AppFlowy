import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_prompt_database_selector_cubit.freezed.dart';

class AiPromptDatabaseSelectorCubit
    extends Cubit<AiPromptDatabaseSelectorState> {
  AiPromptDatabaseSelectorCubit({
    required CustomPromptDatabaseConfig? configuration,
  }) : super(AiPromptDatabaseSelectorState.loading()) {
    _init(configuration);
  }

  void _init(CustomPromptDatabaseConfig? config) async {
    if (config == null) {
      emit(AiPromptDatabaseSelectorState.empty());
      return;
    }

    final fields = await _getFields(config.view.id);

    if (fields == null) {
      emit(AiPromptDatabaseSelectorState.empty());
      return;
    }

    emit(
      AiPromptDatabaseSelectorState.selected(
        config: config,
        fields: fields,
      ),
    );
  }

  void selectDatabaseView(String viewId) async {
    final configuration = await _testDatabase(viewId);

    if (configuration == null) {
      final stateCopy = state;
      emit(AiPromptDatabaseSelectorState.invalidDatabase());
      emit(stateCopy);
      return;
    }

    final databaseView = await AiPromptSelectorCubit.getDatabaseView(viewId);
    final fields = await _getFields(viewId);

    if (databaseView == null || fields == null) {
      final stateCopy = state;
      emit(AiPromptDatabaseSelectorState.invalidDatabase());
      emit(stateCopy);
      return;
    }

    final config = CustomPromptDatabaseConfig.fromDbPB(
      configuration,
      databaseView,
    );

    emit(
      AiPromptDatabaseSelectorState.selected(
        config: config,
        fields: fields,
      ),
    );
  }

  void selectContentField(String fieldId) {
    final state = this.state;
    if (state is! _Selected) {
      return;
    }

    final config = state.config.copyWith(
      contentFieldId: fieldId,
    );

    emit(
      AiPromptDatabaseSelectorState.selected(
        config: config,
        fields: state.fields,
      ),
    );
  }

  void selectExampleField(String? fieldId) {
    final state = this.state;
    if (state is! _Selected) {
      return;
    }

    final config = CustomPromptDatabaseConfig(
      exampleFieldId: fieldId,
      view: state.config.view,
      titleFieldId: state.config.titleFieldId,
      contentFieldId: state.config.contentFieldId,
      categoryFieldId: state.config.categoryFieldId,
    );

    emit(
      AiPromptDatabaseSelectorState.selected(
        config: config,
        fields: state.fields,
      ),
    );
  }

  void selectCategoryField(String? fieldId) {
    final state = this.state;
    if (state is! _Selected) {
      return;
    }

    final config = CustomPromptDatabaseConfig(
      categoryFieldId: fieldId,
      view: state.config.view,
      titleFieldId: state.config.titleFieldId,
      contentFieldId: state.config.contentFieldId,
      exampleFieldId: state.config.exampleFieldId,
    );

    emit(
      AiPromptDatabaseSelectorState.selected(
        config: config,
        fields: state.fields,
      ),
    );
  }

  Future<List<FieldPB>?> _getFields(String viewId) {
    return FieldBackendService.getFields(viewId: viewId).toNullable();
  }

  Future<CustomPromptDatabaseConfigPB?> _testDatabase(
    String viewId,
  ) {
    return DatabaseEventTestCustomPromptDatabaseConfiguration(
      DatabaseViewIdPB(value: viewId),
    ).send().toNullable();
  }
}

@freezed
class AiPromptDatabaseSelectorState with _$AiPromptDatabaseSelectorState {
  const factory AiPromptDatabaseSelectorState.loading() = _Loading;

  const factory AiPromptDatabaseSelectorState.empty() = _Empty;

  const factory AiPromptDatabaseSelectorState.selected({
    required CustomPromptDatabaseConfig config,
    required List<FieldPB> fields,
  }) = _Selected;

  const factory AiPromptDatabaseSelectorState.invalidDatabase() =
      _InvalidDatabase;
}
