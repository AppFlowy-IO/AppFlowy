import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/field/grid_listenr.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
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
  final RowService rowService;
  final RowListener rowlistener;
  final GridFieldsListener fieldListener;

  RowBloc({required RowData rowData, required this.rowlistener})
      : rowService = RowService(
          gridId: rowData.gridId,
          blockId: rowData.blockId,
          rowId: rowData.rowId,
        ),
        fieldListener = GridFieldsListener(
          gridId: rowData.gridId,
        ),
        super(RowState.initial(rowData)) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            _startListening();
            await _loadRow(emit);
          },
          createRow: (_CreateRow value) {
            rowService.createRow();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) async {
            await _handleFieldUpdate(emit, value);
          },
          didUpdateRow: (_DidUpdateRow value) async {
            _handleRowUpdate(value, emit);
          },
        );
      },
    );
  }

  void _handleRowUpdate(_DidUpdateRow value, Emitter<RowState> emit) {
    final CellDataMap cellDataMap = _makeCellDatas(value.row);
    emit(state.copyWith(
      row: Future(() => Some(value.row)),
      cellDataMap: Some(cellDataMap),
    ));
  }

  Future<void> _handleFieldUpdate(Emitter<RowState> emit, _DidReceiveFieldUpdate value) async {
    final optionRow = await state.row;
    final CellDataMap cellDataMap = optionRow.fold(
      () => CellDataMap.identity(),
      (row) => _makeCellDatas(row),
    );

    emit(state.copyWith(
      fields: value.fields,
      cellDataMap: Some(cellDataMap),
    ));
  }

  @override
  Future<void> close() async {
    await rowlistener.stop();
    await fieldListener.stop();
    return super.close();
  }

  Future<void> _startListening() async {
    rowlistener.updateRowNotifier.addPublishListener((result) {
      result.fold(
        (row) => add(RowEvent.didUpdateRow(row)),
        (err) => Log.error(err),
      );
    });

    fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (fields) => add(RowEvent.didReceiveFieldUpdate(fields)),
        (err) => Log.error(err),
      );
    });

    rowlistener.start();
    fieldListener.start();
  }

  Future<void> _loadRow(Emitter<RowState> emit) async {
    rowService.getRow().then((result) {
      return result.fold(
        (row) => add(RowEvent.didUpdateRow(row)),
        (err) => Log.error(err),
      );
    });
  }

  CellDataMap _makeCellDatas(Row row) {
    var map = CellDataMap.new();
    for (final field in state.fields) {
      if (field.visibility) {
        map[field.id] = CellData(
          rowId: row.id,
          gridId: rowService.gridId,
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
  const factory RowEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
  const factory RowEvent.didUpdateRow(Row row) = _DidUpdateRow;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required String rowId,
    required double rowHeight,
    required List<Field> fields,
    required Future<Option<Row>> row,
    required Option<CellDataMap> cellDataMap,
  }) = _RowState;

  factory RowState.initial(RowData data) => RowState(
        rowId: data.rowId,
        rowHeight: data.height,
        fields: data.fields,
        row: Future(() => none()),
        cellDataMap: none(),
      );
}
