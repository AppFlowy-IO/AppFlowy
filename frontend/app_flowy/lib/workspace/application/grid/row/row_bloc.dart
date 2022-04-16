import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_listener.dart';
import 'row_service.dart';
import 'package:dartz/dartz.dart';

part 'row_bloc.freezed.dart';

typedef CellDataMap = LinkedHashMap<String, CellData>;

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService _rowService;
  final RowListener _rowlistener;
  final GridFieldCache _fieldCache;

  RowBloc({required RowData rowData, required GridFieldCache fieldCache})
      : _rowService = RowService(gridId: rowData.gridId, rowId: rowData.rowId),
        _fieldCache = fieldCache,
        _rowlistener = RowListener(rowId: rowData.rowId),
        super(RowState.initial(rowData)) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            await _startListening();
            await _loadRow(emit);
          },
          createRow: (_CreateRow value) {
            _rowService.createRow();
          },
          didUpdateRow: (_DidUpdateRow value) async {
            _handleRowUpdate(value.row, emit);
          },
          fieldsDidUpdate: (_FieldsDidUpdate value) async {
            await _handleFieldUpdate(emit);
          },
          didLoadRow: (_DidLoadRow value) {
            _handleRowUpdate(value.row, emit);
          },
        );
      },
    );
  }

  void _handleRowUpdate(Row row, Emitter<RowState> emit) {
    final CellDataMap cellDataMap = _makeCellDatas(row, state.rowData.fields);
    emit(state.copyWith(
      row: Future(() => Some(row)),
      cellDataMap: Some(cellDataMap),
    ));
  }

  Future<void> _handleFieldUpdate(Emitter<RowState> emit) async {
    final optionRow = await state.row;
    final CellDataMap cellDataMap = optionRow.fold(
      () => CellDataMap.identity(),
      (row) => _makeCellDatas(row, _fieldCache.unmodifiableFields),
    );

    emit(state.copyWith(
      rowData: state.rowData.copyWith(fields: _fieldCache.unmodifiableFields),
      cellDataMap: Some(cellDataMap),
    ));
  }

  @override
  Future<void> close() async {
    await _rowlistener.stop();
    return super.close();
  }

  Future<void> _startListening() async {
    _rowlistener.updateRowNotifier?.addPublishListener((result) {
      result.fold(
        (row) {
          if (!isClosed) {
            add(RowEvent.didUpdateRow(row));
          }
        },
        (err) => Log.error(err),
      );
    });

    _fieldCache.addListener(() {
      if (!isClosed) {
        add(const RowEvent.fieldsDidUpdate());
      }
    });

    _rowlistener.start();
  }

  Future<void> _loadRow(Emitter<RowState> emit) async {
    _rowService.getRow().then((result) {
      return result.fold(
        (row) {
          if (!isClosed) {
            add(RowEvent.didLoadRow(row));
          }
        },
        (err) => Log.error(err),
      );
    });
  }

  CellDataMap _makeCellDatas(Row row, List<Field> fields) {
    var map = CellDataMap.new();
    for (final field in fields) {
      if (field.visibility) {
        map[field.id] = CellData(
          rowId: row.id,
          gridId: _rowService.gridId,
          cell: row.cellByFieldId[field.id],
          field: field,
        );
      }
    }
    return map;
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.fieldsDidUpdate() = _FieldsDidUpdate;
  const factory RowEvent.didLoadRow(Row row) = _DidLoadRow;
  const factory RowEvent.didUpdateRow(Row row) = _DidUpdateRow;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required RowData rowData,
    required Future<Option<Row>> row,
    required Option<CellDataMap> cellDataMap,
  }) = _RowState;

  factory RowState.initial(RowData rowData) => RowState(
        rowData: rowData,
        row: Future(() => none()),
        cellDataMap: none(),
      );
}
