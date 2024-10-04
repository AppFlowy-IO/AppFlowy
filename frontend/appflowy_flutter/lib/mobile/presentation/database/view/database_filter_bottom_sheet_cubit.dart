import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'database_filter_bottom_sheet_cubit.freezed.dart';

class MobileFilterEditorCubit extends Cubit<MobileFilterEditorState> {
  MobileFilterEditorCubit({
    required this.pageController,
  }) : super(MobileFilterEditorState.overview());

  final PageController pageController;

  void returnToOverview({bool scrollToBottom = false}) {
    _animateToPage(0);
    emit(MobileFilterEditorState.overview(scrollToBottom: scrollToBottom));
  }

  void startCreatingFilter() {
    _animateToPage(1);
    emit(MobileFilterEditorState.create());
  }

  void startEditingFilterField(String filterId) {
    _animateToPage(1);
    emit(MobileFilterEditorState.editField(filterId: filterId));
  }

  void updateFilter(DatabaseFilter filter) {
    emit(
      state.maybeWhen(
        editCondition: (filterId, newFilter, showSave) =>
            MobileFilterEditorState.editCondition(
          filterId: filterId,
          newFilter: filter,
          showSave: showSave,
        ),
        editContent: (filterId, _) => MobileFilterEditorState.editContent(
          filterId: filterId,
          newFilter: filter,
        ),
        orElse: () => state,
      ),
    );
  }

  void startEditingFilterCondition(
    String filterId,
    DatabaseFilter filter,
    bool showSave,
  ) {
    _animateToPage(1);
    emit(
      MobileFilterEditorState.editCondition(
        filterId: filterId,
        newFilter: filter,
        showSave: showSave,
      ),
    );
  }

  void startEditingFilterContent(String filterId, DatabaseFilter filter) {
    _animateToPage(1);
    emit(
      MobileFilterEditorState.editContent(
        filterId: filterId,
        newFilter: filter,
      ),
    );
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
class MobileFilterEditorState with _$MobileFilterEditorState {
  factory MobileFilterEditorState.overview({
    @Default(false) bool scrollToBottom,
  }) = _OverviewState;

  factory MobileFilterEditorState.create() = _CreateState;

  factory MobileFilterEditorState.editField({
    required String filterId,
  }) = _EditFieldState;

  factory MobileFilterEditorState.editCondition({
    required String filterId,
    required DatabaseFilter newFilter,
    required bool showSave,
  }) = _EditConditionState;

  factory MobileFilterEditorState.editContent({
    required String filterId,
    required DatabaseFilter newFilter,
  }) = _EditContentState;
}
