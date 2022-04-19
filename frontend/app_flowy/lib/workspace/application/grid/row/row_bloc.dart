import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_service.dart';
import 'package:dartz/dartz.dart';

part 'row_bloc.freezed.dart';

typedef CellDataMap = LinkedHashMap<String, GridCellIdentifier>;

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService _rowService;
  final GridFieldCache _fieldCache;
  final GridRowCache _rowCache;
  void Function()? _rowListenCallback;
  void Function()? _fieldListenCallback;

  RowBloc({
    required GridRow rowData,
    required GridFieldCache fieldCache,
    required GridRowCache rowCache,
  })  : _rowService = RowService(gridId: rowData.gridId, rowId: rowData.rowId),
        _fieldCache = fieldCache,
        _rowCache = rowCache,
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
    emit(state.copyWith(cellDataMap: Some(cellDataMap)));
  }

  Future<void> _handleFieldUpdate(Emitter<RowState> emit) async {
    final data = state.rowData.data;
    if (data == null) {
      return;
    }

    final CellDataMap cellDataMap = _makeCellDatas(data, state.rowData.fields);
    emit(state.copyWith(cellDataMap: Some(cellDataMap)));
  }

  @override
  Future<void> close() async {
    if (_rowListenCallback != null) {
      _rowCache.removeRowListener(_rowListenCallback!);
    }

    if (_fieldListenCallback != null) {
      _fieldCache.removeListener(_fieldListenCallback!);
    }
    return super.close();
  }

  Future<void> _startListening() async {
    _fieldListenCallback = _fieldCache.addListener(
      listener: () => add(const RowEvent.fieldsDidUpdate()),
      listenWhen: () => !isClosed,
    );

    _rowListenCallback = _rowCache.addRowListener(
      rowId: state.rowData.rowId,
      onUpdated: (row) => add(RowEvent.didUpdateRow(row)),
      listenWhen: () => !isClosed,
    );
  }

  Future<void> _loadRow(Emitter<RowState> emit) async {
    final data = _rowCache.loadRow(state.rowData.rowId);
    data.foldRight(null, (data, _) {
      if (!isClosed) {
        add(RowEvent.didLoadRow(data));
      }
    });
  }

  CellDataMap _makeCellDatas(Row row, List<Field> fields) {
    var map = CellDataMap.new();
    for (final field in fields) {
      if (field.visibility) {
        map[field.id] = GridCellIdentifier(
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
    required GridRow rowData,
    required Option<CellDataMap> cellDataMap,
  }) = _RowState;

  factory RowState.initial(GridRow rowData) => RowState(
        rowData: rowData,
        cellDataMap: none(),
      );
}
