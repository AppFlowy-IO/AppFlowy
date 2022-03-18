import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'grid_service.dart';
import 'row_listener.dart';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService rowService;
  final RowListener listener;

  RowBloc({required this.rowService, required this.listener}) : super(RowState.initial(rowService.rowData)) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            _startRowListening();
            await _loadCellDatas(emit);
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
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.close();
    return super.close();
  }

  Future<void> _startRowListening() async {
    listener.updateRowNotifier.addPublishListener((result) {
      result.fold((row) {
        //
      }, (err) => null);
    });

    listener.updateCellNotifier.addPublishListener((result) {
      result.fold((repeatedCvell) {
        //
        Log.info("$repeatedCvell");
      }, (r) => null);
    });

    listener.start();
  }

  Future<void> _loadCellDatas(Emitter<RowState> emit) async {
    final result = await rowService.getRow();
    result.fold(
      (row) {
        emit(state.copyWith(
          cellDatas: makeGridCellDatas(row),
          rowHeight: row.height.toDouble(),
        ));
      },
      (e) => Log.error(e),
    );
  }

  List<GridCellData> makeGridCellDatas(Row row) {
    return rowService.rowData.fields.map((field) {
      final cell = row.cellByFieldId[field.id];
      final rowData = rowService.rowData;

      return GridCellData(
        rowId: row.id,
        gridId: rowData.gridId,
        blockId: rowData.blockId,
        cell: cell,
        field: field,
      );
    }).toList();
  }
}

@freezed
abstract class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.activeRow() = _ActiveRow;
  const factory RowEvent.disactiveRow() = _DisactiveRow;
}

@freezed
abstract class RowState with _$RowState {
  const factory RowState({
    required String rowId,
    required double rowHeight,
    required List<GridCellData> cellDatas,
    required bool active,
  }) = _RowState;

  factory RowState.initial(GridRowData data) => RowState(
        rowId: data.rowId,
        active: false,
        rowHeight: data.height,
        cellDatas: [],
      );
}
