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
    _loadPrompts();
  }

  final AppFlowyAIService _aiService;
  final filterTextController = TextEditingController();
  final List<AiPrompt> availablePrompts = [];

  @override
  Future<void> close() async {
    filterTextController.dispose();
    await super.close();
  }

  void _loadPrompts() async {
    availablePrompts.addAll(await _aiService.getBuiltInPrompts());
    final visiblePrompts = _getFilteredPrompts(availablePrompts);
    emit(
      AiPromptSelectorState.ready(
        visiblePrompts: visiblePrompts,
        showCustomPrompts: false,
        isFeaturedCategorySelected: false,
        selectedPromptId: visiblePrompts.firstOrNull?.id,
        selectedCategory: null,
        favoritePrompts: [],
      ),
    );
  }

  void selectFeaturedCategory() {
    state.maybeMap(
      ready: (readyState) {
        emit(
          readyState.copyWith(
            // TODO(RS): Add logic to filter prompts based on the featured category
            // visiblePrompts: prompts,
            isFeaturedCategorySelected: true,
            // selectedPromptId: prompts.firstOrNull?.id,
          ),
        );
      },
      orElse: () {},
    );
  }

  void selectCategory(AiPromptCategory? category) {
    state.maybeMap(
      ready: (readyState) {
        final unfilteredPrompts = category == null
            ? availablePrompts
            : availablePrompts.where((prompt) => prompt.category == category);
        final prompts = _getFilteredPrompts(unfilteredPrompts);

        // Check if the selected prompt is still visible
        String? selectedPromptId = prompts.firstOrNull?.id;
        if (readyState.selectedPromptId != null &&
            prompts.any((prompt) => prompt.id == readyState.selectedPromptId)) {
          selectedPromptId = readyState.selectedPromptId;
        }

        emit(
          readyState.copyWith(
            visiblePrompts: prompts,
            isFeaturedCategorySelected: false,
            selectedCategory: category,
            selectedPromptId: selectedPromptId,
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

        // TODO(RS): Save the updated favorite prompts to local storage or database
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
            selectedPromptId: null,
            selectedCategory: null,
          ),
        );
      },
      orElse: () {},
    );
  }

  AiPrompt? get selectedPrompt {
    return state.maybeMap(
      ready: (readyState) {
        return readyState.visiblePrompts.firstWhereOrNull(
          (prompt) => prompt.id == readyState.selectedPromptId,
        );
      },
      orElse: () => null,
    );
  }

  void _filterTextChanged() {
    state.maybeMap(
      ready: (readyState) {
        final unfilteredPrompts = readyState.selectedCategory == null
            ? availablePrompts
            : availablePrompts.where(
                (prompt) => prompt.category == readyState.selectedCategory,
              );
        final filteredPrompts = _getFilteredPrompts(unfilteredPrompts);

        emit(
          readyState.copyWith(visiblePrompts: filteredPrompts),
        );
      },
      orElse: () {},
    );
  }

  List<AiPrompt> _getFilteredPrompts(Iterable<AiPrompt> prompts) {
    final filterText = filterTextController.value.text.trim().toLowerCase();

    return prompts.where((prompt) {
      final content = "${prompt.name} ${prompt.name}".toLowerCase();
      return content.contains(filterText);
    }).toList();
  }
}

@freezed
class AiPromptSelectorState with _$AiPromptSelectorState {
  const AiPromptSelectorState._();

  const factory AiPromptSelectorState.loading() = _AiPromptSelectorLoadingState;

  const factory AiPromptSelectorState.ready({
    required List<AiPrompt> visiblePrompts,
    required List<String> favoritePrompts,
    required bool showCustomPrompts,
    required bool isFeaturedCategorySelected,
    required AiPromptCategory? selectedCategory,
    required String? selectedPromptId,
  }) = _AiPromptSelectorReadyState;

  bool get isLoading => this is _AiPromptSelectorLoadingState;
  bool get isReady => this is _AiPromptSelectorReadyState;

  AiPrompt? get selectedPrompt => maybeMap(
        ready: (state) => state.visiblePrompts
            .firstWhereOrNull((prompt) => prompt.id == state.selectedPromptId),
        orElse: () => null,
      );

  AiPromptCategory? get selectedCategory => maybeMap(
        ready: (state) => state.selectedCategory,
        orElse: () => null,
      );
}
