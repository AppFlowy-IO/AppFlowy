import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_row_search_bloc.freezed.dart';

class RelationRowSearchBloc
    extends Bloc<RelationRowSearchEvent, RelationRowSearchState> {
  RelationRowSearchBloc({
    required this.databaseId,
  }) : super(RelationRowSearchState.initial()) {
    _dispatch();
    _init();
  }

  final String databaseId;
  final List<RelatedRowDataPB> allRows = [];

  void _dispatch() {
    on<RelationRowSearchEvent>(
      (event, emit) {
        event.when(
          didUpdateRowList: (List<RelatedRowDataPB> rowList) {
            allRows
              ..clear()
              ..addAll(rowList);
            emit(
              state.copyWith(
                filteredRows: allRows,
                focusedRowId: state.focusedRowId ?? allRows.firstOrNull?.rowId,
              ),
            );
          },
          updateFilter: (String filter) => _updateFilter(filter, emit),
          updateFocusedOption: (String rowId) {
            emit(state.copyWith(focusedRowId: rowId));
          },
          focusPreviousOption: () => _focusOption(true, emit),
          focusNextOption: () => _focusOption(false, emit),
        );
      },
    );
  }

  Future<void> _init() async {
    final payload = DatabaseIdPB(value: databaseId);
    final result = await DatabaseEventGetRelatedDatabaseRows(payload).send();
    result.fold(
      (data) => add(RelationRowSearchEvent.didUpdateRowList(data.rows)),
      (err) => Log.error(err),
    );
  }

  void _updateFilter(String filter, Emitter<RelationRowSearchState> emit) {
    final rows = [...allRows];

    if (filter.isNotEmpty) {
      rows.retainWhere(
        (row) =>
            row.name.toLowerCase().contains(filter.toLowerCase()) ||
            (row.name.isEmpty &&
                LocaleKeys.grid_row_titlePlaceholder
                    .tr()
                    .toLowerCase()
                    .contains(filter.toLowerCase())),
      );
    }

    final focusedRowId = rows.isEmpty
        ? null
        : rows.any((row) => row.rowId == state.focusedRowId)
            ? state.focusedRowId
            : rows.first.rowId;

    emit(
      state.copyWith(
        filteredRows: rows,
        focusedRowId: focusedRowId,
      ),
    );
  }

  void _focusOption(bool previous, Emitter<RelationRowSearchState> emit) {
    if (state.filteredRows.isEmpty) {
      return;
    }

    final rowIds = state.filteredRows.map((e) => e.rowId).toList();
    final currentIndex = state.focusedRowId == null
        ? -1
        : rowIds.indexWhere((id) => id == state.focusedRowId);

    // If the current index is -1, it means that the focused row is not in the list of row ids.
    // In this case, we set the new index to the last index if previous is true, otherwise to 0.
    final newIndex = currentIndex == -1
        ? (previous ? rowIds.length - 1 : 0)
        : (currentIndex + (previous ? -1 : 1)) % rowIds.length;

    emit(state.copyWith(focusedRowId: rowIds[newIndex]));
  }
}

@freezed
class RelationRowSearchEvent with _$RelationRowSearchEvent {
  const factory RelationRowSearchEvent.didUpdateRowList(
    List<RelatedRowDataPB> rowList,
  ) = _DidUpdateRowList;
  const factory RelationRowSearchEvent.updateFilter(String filter) =
      _UpdateFilter;
  const factory RelationRowSearchEvent.updateFocusedOption(
    String rowId,
  ) = _UpdateFocusedOption;
  const factory RelationRowSearchEvent.focusPreviousOption() =
      _FocusPreviousOption;
  const factory RelationRowSearchEvent.focusNextOption() = _FocusNextOption;
}

@freezed
class RelationRowSearchState with _$RelationRowSearchState {
  const factory RelationRowSearchState({
    required List<RelatedRowDataPB> filteredRows,
    required String? focusedRowId,
  }) = _RelationRowSearchState;

  factory RelationRowSearchState.initial() => const RelationRowSearchState(
        filteredRows: [],
        focusedRowId: null,
      );
}
