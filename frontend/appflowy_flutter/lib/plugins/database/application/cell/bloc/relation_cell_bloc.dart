import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_cell_bloc.freezed.dart';

class RelationCellBloc extends Bloc<RelationCellEvent, RelationCellState> {
  RelationCellBloc({required this.cellController})
      : super(RelationCellState.initial()) {
    _dispatch();
    _startListening();
    _init();
  }

  final RelationCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    return super.close();
  }

  void _dispatch() {
    on<RelationCellEvent>(
      (event, emit) async {
        await event.when(
          didUpdateCell: (RelationCellDataPB? cellData) async {
            if (cellData == null || cellData.rowIds.isEmpty) {
              emit(state.copyWith(rows: const []));
              return;
            }
            final payload = RepeatedRowIdPB(
              databaseId: state.relatedDatabaseId,
              rowIds: cellData.rowIds,
            );
            final result =
                await DatabaseEventGetRelatedRowDatas(payload).send();
            final rows = result.fold(
              (data) => data.rows,
              (err) {
                Log.error(err);
                return const <RelatedRowDataPB>[];
              },
            );
            emit(state.copyWith(rows: rows));
          },
          didUpdateRelationDatabaseId: (databaseId) {
            emit(state.copyWith(relatedDatabaseId: databaseId));
          },
          selectRow: (rowId) async {
            await _handleSelectRow(rowId);
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(RelationCellEvent.didUpdateCell(data));
        }
      },
      onCellFieldChanged: (field) {
        if (!isClosed) {
          // hack: SingleFieldListener receives notification before
          // FieldController's copy is updated.
          Future.delayed(const Duration(milliseconds: 50), () {
            final RelationTypeOptionPB typeOption =
                cellController.getTypeOption(RelationTypeOptionDataParser());
            add(
              RelationCellEvent.didUpdateRelationDatabaseId(
                typeOption.databaseId,
              ),
            );
          });
        }
      },
    );
  }

  void _init() {
    final RelationTypeOptionPB typeOption =
        cellController.getTypeOption(RelationTypeOptionDataParser());
    add(RelationCellEvent.didUpdateRelationDatabaseId(typeOption.databaseId));
    final cellData = cellController.getCellData();
    add(RelationCellEvent.didUpdateCell(cellData));
  }

  Future<void> _handleSelectRow(String rowId) async {
    final payload = RelationCellChangesetPB(
      viewId: cellController.viewId,
      cellId: CellIdPB(
        viewId: cellController.viewId,
        fieldId: cellController.fieldId,
        rowId: cellController.rowId,
      ),
    );
    if (state.rows.any((row) => row.rowId == rowId)) {
      payload.removedRowIds.add(rowId);
    } else {
      payload.insertedRowIds.add(rowId);
    }
    final result = await DatabaseEventUpdateRelationCell(payload).send();
    result.fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class RelationCellEvent with _$RelationCellEvent {
  const factory RelationCellEvent.didUpdateRelationDatabaseId(
    String databaseId,
  ) = _DidUpdateRelationDatabaseId;
  const factory RelationCellEvent.didUpdateCell(RelationCellDataPB? data) =
      _DidUpdateCell;
  const factory RelationCellEvent.selectRow(String rowId) = _SelectRowId;
}

@freezed
class RelationCellState with _$RelationCellState {
  const factory RelationCellState({
    required String relatedDatabaseId,
    required List<RelatedRowDataPB> rows,
  }) = _RelationCellState;

  factory RelationCellState.initial() =>
      const RelationCellState(relatedDatabaseId: "", rows: []);
}
