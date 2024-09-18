import 'package:appflowy/plugins/database/application/field/field_info.dart';
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

  void returnToOverview() {
    _animateToPage(0);
    emit(MobileFilterEditorState.overview());
  }

  void startCreatingFilter() {
    _animateToPage(1);
    emit(MobileFilterEditorState.create(filterField: null));
  }

  void startEditingFilterField(String filterId) {
    _animateToPage(1);
    emit(MobileFilterEditorState.editField(filterId: filterId, newField: null));
  }

  void changeField(FieldInfo field) {
    emit(
      state.maybeWhen(
        create: (_) => MobileFilterEditorState.create(
          filterField: field,
        ),
        editField: (filterId, _) => MobileFilterEditorState.editField(
          filterId: filterId,
          newField: field,
        ),
        orElse: () => state,
      ),
    );
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
  factory MobileFilterEditorState.overview() = _OverviewState;

  factory MobileFilterEditorState.create({
    required FieldInfo? filterField,
  }) = _CreateState;

  factory MobileFilterEditorState.editField({
    required String filterId,
    required FieldInfo? newField,
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
