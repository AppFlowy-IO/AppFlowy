import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
        customPromptDatabaseViewId: null,
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

        String? databaseViewId = readyState.customPromptDatabaseViewId;
        if (databaseViewId == null) {
          final result =
              await AIEventGetCustomPromptDatabaseViewId().send().toNullable();
          databaseViewId = result?.id;
        }

        if (databaseViewId == null) {
          emit(
            readyState.copyWith(isLoadingCustomPrompts: false),
          );
          return;
        }

        availablePrompts.removeWhere((prompt) => prompt.isCustom);

        final customPrompts =
            await _aiService.getDatabasePrompts(databaseViewId);

        if (customPrompts == null || customPrompts.isEmpty) {
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
              customPromptDatabaseViewId: databaseViewId,
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
              customPromptDatabaseViewId: databaseViewId,
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
            : availablePrompts.where((prompt) => prompt.category == category);
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

  void updateCustomPromptDatabaseViewId(String viewId) async {
    final stateCopy = state;
    final newState = state.maybeMap(
      ready: (readyState) {
        return readyState.customPromptDatabaseViewId == viewId
            ? null
            : readyState.copyWith(isLoadingCustomPrompts: true);
      },
      orElse: () => null,
    );

    if (newState == null) {
      return;
    }
    emit(newState);

    await Future.delayed(const Duration(seconds: 1));

    final customPrompts = await _aiService.getDatabasePrompts(viewId);
    if (customPrompts == null) {
      emit(AiPromptSelectorState.invalidDatabase());
      emit(stateCopy);

      return;
    }

    availablePrompts
      ..removeWhere((prompt) => prompt.isCustom)
      ..addAll(customPrompts);

    await AIEventSetCustomPromptDatabaseViewId(
      CustomPromptDatabaseViewIdPB()..id = viewId,
    ).send().onFailure(Log.error);

    emit(
      state.maybeMap(
        ready: (readyState) {
          if (customPrompts.isEmpty) {
            final prompts =
                availablePrompts.where((prompt) => prompt.isFeatured);
            final visiblePrompts = _getFilteredPrompts(prompts);
            final selectedPromptId = _getVisibleSelectedPrompt(
              visiblePrompts,
              readyState.selectedPromptId,
            );
            return readyState.copyWith(
              visiblePrompts: visiblePrompts.toList(),
              selectedPromptId: selectedPromptId,
              customPromptDatabaseViewId: viewId,
              isLoadingCustomPrompts: false,
              isFeaturedSectionSelected: true,
              isCustomPromptSectionSelected: false,
              selectedCategory: null,
            );
          } else {
            final prompts = _getPromptsByCategory(readyState);
            final visiblePrompts = _getFilteredPrompts(prompts);
            final selectedPromptId = _getVisibleSelectedPrompt(
              visiblePrompts,
              readyState.selectedPromptId,
            );
            return readyState.copyWith(
              visiblePrompts: visiblePrompts.toList(),
              selectedPromptId: selectedPromptId,
              customPromptDatabaseViewId: viewId,
              isLoadingCustomPrompts: false,
            );
          }
        },
        orElse: () => state,
      ),
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
        return prompt.category == state.selectedCategory;
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
    required String? customPromptDatabaseViewId,
  }) = _AiPromptSelectorReadyState;

  bool get isLoading => this is _AiPromptSelectorLoadingState;
  bool get isReady => this is _AiPromptSelectorReadyState;

  AiPrompt? get selectedPrompt => maybeMap(
        ready: (state) => state.visiblePrompts
            .firstWhereOrNull((prompt) => prompt.id == state.selectedPromptId),
        orElse: () => null,
      );
}
