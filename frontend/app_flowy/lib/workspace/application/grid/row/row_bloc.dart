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

typedef CellDataMap = HashMap<String, GridCellData>;

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService rowService;
  final RowListener rowlistener;
  final GridFieldsListener fieldListener;

  RowBloc({required GridRowData rowData, required this.rowlistener})
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
            add(const RowEvent.didUpdateCell());
          },
          createRow: (_CreateRow value) {
            rowService.createRow();
          },
          activeRow: (_ActiveRow value) {
            emit(state.copyWith(active: true));
          },
          disactiveRow: (_DisactiveRow value) {
            emit(state.copyWith(active: false));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
            add(const RowEvent.didUpdateCell());
          },
          didUpdateCell: (_DidUpdateCell value) async {
            final optionRow = await state.row;
            final CellDataMap cellDataMap = optionRow.fold(
              () => HashMap.identity(),
              (row) => _makeCellDatas(row),
            );
            emit(state.copyWith(cellDataMap: cellDataMap));
          },
        );
      },
    );
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
        (row) {
          //
        },
        (err) => Log.error(err),
      );
    });

    rowlistener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (repeatedCell) {
          Log.info("$repeatedCell");
        },
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
    final Future<Option<Row>> row = rowService.getRow().then((result) {
      return result.fold(
        (row) => Some(row),
        (err) {
          Log.error(err);
          return none();
        },
      );
    });
    emit(state.copyWith(row: row));
  }

  CellDataMap _makeCellDatas(Row row) {
    var map = CellDataMap.new();
    for (final field in state.fields) {
      map[field.id] = GridCellData(
        rowId: row.id,
        gridId: rowService.gridId,
        blockId: rowService.blockId,
        cell: row.cellByFieldId[field.id],
        field: field,
      );
    }
    return map;
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.activeRow() = _ActiveRow;
  const factory RowEvent.disactiveRow() = _DisactiveRow;
  const factory RowEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
  const factory RowEvent.didUpdateCell() = _DidUpdateCell;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required String rowId,
    required bool active,
    required double rowHeight,
    required List<Field> fields,
    required Future<Option<Row>> row,
    required CellDataMap? cellDataMap,
  }) = _RowState;

  factory RowState.initial(GridRowData data) => RowState(
        rowId: data.rowId,
        active: false,
        rowHeight: data.height,
        fields: data.fields,
        row: Future(() => none()),
        cellDataMap: null,
      );
}
