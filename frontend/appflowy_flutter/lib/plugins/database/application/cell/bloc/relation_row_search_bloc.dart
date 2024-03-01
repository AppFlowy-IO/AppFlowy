import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
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
            allRows.clear();
            allRows.addAll(rowList);
            emit(state.copyWith(filteredRows: allRows));
          },
          updateFilter: (String filter) => _updateFilter(filter, emit),
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
        (row) => row.name.toLowerCase().contains(filter.toLowerCase()),
      );
    }
    emit(state.copyWith(filter: filter, filteredRows: rows));
  }
}

@freezed
class RelationRowSearchEvent with _$RelationRowSearchEvent {
  const factory RelationRowSearchEvent.didUpdateRowList(
    List<RelatedRowDataPB> rowList,
  ) = _DidUpdateRowList;
  const factory RelationRowSearchEvent.updateFilter(String filter) =
      _UpdateFilter;
}

@freezed
class RelationRowSearchState with _$RelationRowSearchState {
  const factory RelationRowSearchState({
    required String filter,
    required List<RelatedRowDataPB> filteredRows,
  }) = _RelationRowSearchState;

  factory RelationRowSearchState.initial() => const RelationRowSearchState(
        filter: "",
        filteredRows: [],
      );
}
