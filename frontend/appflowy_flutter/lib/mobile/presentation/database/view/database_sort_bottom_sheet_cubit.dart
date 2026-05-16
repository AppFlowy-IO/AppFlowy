import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'database_sort_bottom_sheet_cubit.freezed.dart';

class MobileSortEditorCubit extends Cubit<MobileSortEditorState> {
  MobileSortEditorCubit({
    required this.pageController,
  }) : super(MobileSortEditorState.initial());

  final PageController pageController;

  void returnToOverview() {
    _animateToPage(0);
    emit(MobileSortEditorState.initial());
  }

  void startCreatingSort() {
    _animateToPage(1);
    emit(
      state.copyWith(
        showBackButton: true,
        isCreatingNewSort: true,
        newSortCondition: SortConditionPB.Ascending,
      ),
    );
  }

  void startEditingSort(String sortId) {
    _animateToPage(1);
    emit(
      state.copyWith(
        showBackButton: true,
        editingSortId: sortId,
      ),
    );
  }

  /// only used when creating a new sort
  void changeFieldId(String fieldId) {
    emit(state.copyWith(newSortFieldId: fieldId));
  }

  /// only used when creating a new sort
  void changeSortCondition(SortConditionPB condition) {
    emit(state.copyWith(newSortCondition: condition));
  }

  Future<void> _animateToPage(int page) async {
    return pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }
}

@freezed
class MobileSortEditorState with _$MobileSortEditorState {
  factory MobileSortEditorState({
    required bool showBackButton,
    required String? editingSortId,
    required bool isCreatingNewSort,
    required String? newSortFieldId,
    required SortConditionPB? newSortCondition,
  }) = _MobileSortEditorState;

  factory MobileSortEditorState.initial() => MobileSortEditorState(
        showBackButton: false,
        editingSortId: null,
        isCreatingNewSort: false,
        newSortFieldId: null,
        newSortCondition: null,
      );
}
