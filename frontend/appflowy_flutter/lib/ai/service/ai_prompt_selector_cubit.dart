import 'dart:async';

import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../plugins/trash/application/trash_service.dart';
import 'ai_entities.dart';
import 'appflowy_ai_service.dart';

part 'ai_prompt_selector_cubit.freezed.dart';

class AiPromptSelectorCubit extends Cubit<AiPromptSelectorState> {
  AiPromptSelectorCubit({
    AppFlowyAIService? aiService,
  })  : _aiService = aiService ?? AppFlowyAIService(),
        super(AiPromptSelectorState.loading()) {
    filterTextController.addListener(_filterTextChanged);
    _init();
  }

  final AppFlowyAIService _aiService;
  final filterTextController = TextEditingController();
  final List<AiPrompt> availablePrompts = [];

  @override
  Future<void> close() async {
    filterTextController.dispose();
    await super.close();
  }

  void _init() async {
    availablePrompts.addAll(await _aiService.getBuiltInPrompts());

    final featuredPrompts =
        availablePrompts.where((prompt) => prompt.isFeatured);
    final visiblePrompts = _getFilteredPrompts(featuredPrompts);

    emit(
      AiPromptSelectorState.ready(
        visiblePrompts: visiblePrompts.toList(),
        isCustomPromptSectionSelected: false,
        isFeaturedSectionSelected: true,
        selectedPromptId: visiblePrompts.firstOrNull?.id,
        databaseConfig: null,
        isLoadingCustomPrompts: true,
        selectedCategory: null,
        favoritePrompts: [],
      ),
    );

    loadCustomPrompts();
  }

  void loadCustomPrompts() {
    state.maybeMap(
      ready: (readyState) async {
        emit(
          readyState.copyWith(isLoadingCustomPrompts: true),
        );

        CustomPromptDatabaseConfig? configuration = readyState.databaseConfig;
        if (configuration == null) {
          final configResult =
              await AIEventGetCustomPromptDatabaseConfiguration()
                  .send()
                  .toNullable();
          if (configResult != null) {
            final view = await getDatabaseView(configResult.viewId);
            if (view != null) {
              configuration = CustomPromptDatabaseConfig.fromAiPB(
                configResult,
                view,
              );
            }
          }
        } else {
          final view = await getDatabaseView(configuration.view.id);
          if (view != null) {
            configuration = configuration.copyWith(view: view);
          }
        }

        if (configuration == null) {
          emit(
            readyState.copyWith(isLoadingCustomPrompts: false),
          );
          return;
        }

        availablePrompts.removeWhere((prompt) => prompt.isCustom);

        final customPrompts =
            await _aiService.getDatabasePrompts(configuration.toDbPB());

        if (customPrompts == null) {
          final prompts = availablePrompts.where((prompt) => prompt.isFeatured);
          final visiblePrompts = _getFilteredPrompts(prompts);
          final selectedPromptId = _getVisibleSelectedPrompt(
            visiblePrompts,
            readyState.selectedPromptId,
          );

          emit(
            readyState.copyWith(
              visiblePrompts: visiblePrompts.toList(),
              selectedPromptId: selectedPromptId,
              databaseConfig: configuration,
              isLoadingCustomPrompts: false,
              isFeaturedSectionSelected: true,
              isCustomPromptSectionSelected: false,
              selectedCategory: null,
            ),
          );
        } else {
          availablePrompts.addAll(customPrompts);

          final prompts = _getPromptsByCategory(readyState);
          final visiblePrompts = _getFilteredPrompts(prompts);
          final selectedPromptId = _getVisibleSelectedPrompt(
            visiblePrompts,
            readyState.selectedPromptId,
          );

          emit(
            readyState.copyWith(
              visiblePrompts: visiblePrompts.toList(),
              databaseConfig: configuration,
              isLoadingCustomPrompts: false,
              selectedPromptId: selectedPromptId,
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  void selectCustomSection() {
    state.maybeMap(
      ready: (readyState) {
        final prompts = availablePrompts.where((prompt) => prompt.isCustom);
        final visiblePrompts = _getFilteredPrompts(prompts);

        emit(
          readyState.copyWith(
            visiblePrompts: visiblePrompts.toList(),
            selectedPromptId: visiblePrompts.firstOrNull?.id,
            isCustomPromptSectionSelected: true,
            isFeaturedSectionSelected: false,
            selectedCategory: null,
          ),
        );
      },
      orElse: () {},
    );
  }

  void selectFeaturedSection() {
    state.maybeMap(
      ready: (readyState) {
        final prompts = availablePrompts.where((prompt) => prompt.isFeatured);
        final visiblePrompts = _getFilteredPrompts(prompts);

        emit(
          readyState.copyWith(
            visiblePrompts: visiblePrompts.toList(),
            selectedPromptId: visiblePrompts.firstOrNull?.id,
            isFeaturedSectionSelected: true,
            isCustomPromptSectionSelected: false,
            selectedCategory: null,
          ),
        );
      },
      orElse: () {},
    );
  }

  void selectCategory(AiPromptCategory? category) {
    state.maybeMap(
      ready: (readyState) {
        final prompts = category == null
            ? availablePrompts
            : availablePrompts
                .where((prompt) => prompt.category.contains(category));
        final visiblePrompts = _getFilteredPrompts(prompts);

        final selectedPromptId = _getVisibleSelectedPrompt(
          visiblePrompts,
          readyState.selectedPromptId,
        );

        emit(
          readyState.copyWith(
            visiblePrompts: visiblePrompts.toList(),
            selectedCategory: category,
            selectedPromptId: selectedPromptId,
            isFeaturedSectionSelected: false,
            isCustomPromptSectionSelected: false,
          ),
        );
      },
      orElse: () {},
    );
  }

  void selectPrompt(String promptId) {
    state.maybeMap(
      ready: (readyState) {
        final selectedPrompt = readyState.visiblePrompts
            .firstWhereOrNull((prompt) => prompt.id == promptId);
        if (selectedPrompt != null) {
          emit(
            readyState.copyWith(selectedPromptId: selectedPrompt.id),
          );
        }
      },
      orElse: () {},
    );
  }

  void toggleFavorite(String promptId) {
    state.maybeMap(
      ready: (readyState) {
        final favoritePrompts = [...readyState.favoritePrompts];
        if (favoritePrompts.contains(promptId)) {
          favoritePrompts.remove(promptId);
        } else {
          favoritePrompts.add(promptId);
        }
        emit(
          readyState.copyWith(favoritePrompts: favoritePrompts),
        );
      },
      orElse: () {},
    );
  }

  void reset() {
    filterTextController.clear();
    state.maybeMap(
      ready: (readyState) {
        emit(
          readyState.copyWith(
            visiblePrompts: availablePrompts,
            isCustomPromptSectionSelected: false,
            isFeaturedSectionSelected: true,
            selectedPromptId: availablePrompts.firstOrNull?.id,
            selectedCategory: null,
          ),
        );
      },
      orElse: () {},
    );
  }

  void updateCustomPromptDatabaseConfiguration(
    CustomPromptDatabaseConfig configuration,
  ) async {
    state.maybeMap(
      ready: (readyState) async {
        emit(
          readyState.copyWith(isLoadingCustomPrompts: true),
        );

        final customPrompts =
            await _aiService.getDatabasePrompts(configuration.toDbPB());

        if (customPrompts == null) {
          emit(AiPromptSelectorState.invalidDatabase());
          emit(readyState);
          return;
        }

        availablePrompts
          ..removeWhere((prompt) => prompt.isCustom)
          ..addAll(customPrompts);

        await AIEventSetCustomPromptDatabaseConfiguration(
          configuration.toAiPB(),
        ).send().onFailure(Log.error);

        final prompts = _getPromptsByCategory(readyState);
        final visiblePrompts = _getFilteredPrompts(prompts);
        final selectedPromptId = _getVisibleSelectedPrompt(
          visiblePrompts,
          readyState.selectedPromptId,
        );
        emit(
          readyState.copyWith(
            visiblePrompts: visiblePrompts.toList(),
            selectedPromptId: selectedPromptId,
            databaseConfig: configuration,
            isLoadingCustomPrompts: false,
          ),
        );
      },
      orElse: () => {},
    );
  }

  void _filterTextChanged() {
    state.maybeMap(
      ready: (readyState) {
        final prompts = _getPromptsByCategory(readyState);
        final visiblePrompts = _getFilteredPrompts(prompts);

        final selectedPromptId = _getVisibleSelectedPrompt(
          visiblePrompts,
          readyState.selectedPromptId,
        );

        emit(
          readyState.copyWith(
            visiblePrompts: visiblePrompts.toList(),
            selectedPromptId: selectedPromptId,
          ),
        );
      },
      orElse: () {},
    );
  }

  Iterable<AiPrompt> _getFilteredPrompts(Iterable<AiPrompt> prompts) {
    final filterText = filterTextController.value.text.trim().toLowerCase();

    return prompts.where((prompt) {
      final content = "${prompt.name} ${prompt.name}".toLowerCase();
      return content.contains(filterText);
    }).toList();
  }

  Iterable<AiPrompt> _getPromptsByCategory(_AiPromptSelectorReadyState state) {
    return availablePrompts.where((prompt) {
      if (state.selectedCategory != null) {
        return prompt.category.contains(state.selectedCategory);
      }
      if (state.isFeaturedSectionSelected) {
        return prompt.isFeatured;
      }
      if (state.isCustomPromptSectionSelected) {
        return prompt.isCustom;
      }
      return true;
    });
  }

  String? _getVisibleSelectedPrompt(
    Iterable<AiPrompt> visiblePrompts,
    String? currentlySelectedPromptId,
  ) {
    if (visiblePrompts
        .any((prompt) => prompt.id == currentlySelectedPromptId)) {
      return currentlySelectedPromptId;
    }

    return visiblePrompts.firstOrNull?.id;
  }

  static Future<ViewPB?> getDatabaseView(String viewId) async {
    final view = await ViewBackendService.getView(viewId).toNullable();

    if (view != null) {
      return view;
    }

    final trashViews = await TrashService().readTrash().toNullable();
    final trashedItem =
        trashViews?.items.firstWhereOrNull((element) => element.id == viewId);

    if (trashedItem == null) {
      return null;
    }

    return ViewPB()
      ..id = trashedItem.id
      ..name = trashedItem.name;
  }
}

@freezed
class AiPromptSelectorState with _$AiPromptSelectorState {
  const AiPromptSelectorState._();

  const factory AiPromptSelectorState.loading() = _AiPromptSelectorLoadingState;

  const factory AiPromptSelectorState.invalidDatabase() =
      _AiPromptSelectorErrorState;

  const factory AiPromptSelectorState.ready({
    required List<AiPrompt> visiblePrompts,
    required List<String> favoritePrompts,
    required bool isCustomPromptSectionSelected,
    required bool isFeaturedSectionSelected,
    required AiPromptCategory? selectedCategory,
    required String? selectedPromptId,
    required bool isLoadingCustomPrompts,
    required CustomPromptDatabaseConfig? databaseConfig,
  }) = _AiPromptSelectorReadyState;

  bool get isLoading => this is _AiPromptSelectorLoadingState;
  bool get isReady => this is _AiPromptSelectorReadyState;

  AiPrompt? get selectedPrompt => maybeMap(
        ready: (state) => state.visiblePrompts
            .firstWhereOrNull((prompt) => prompt.id == state.selectedPromptId),
        orElse: () => null,
      );
}
