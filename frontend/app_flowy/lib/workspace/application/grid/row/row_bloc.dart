import 'dart:collection';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_service.dart';
import 'package:dartz/dartz.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService _rowService;
  final GridRowCache _rowCache;
  void Function()? _rowListenFn;

  RowBloc({
    required GridRow rowData,
    required GridRowCache rowCache,
  })  : _rowService = RowService(gridId: rowData.gridId, rowId: rowData.rowId),
        _rowCache = rowCache,
        super(RowState.initial(rowData, rowCache.loadCellData(rowData.rowId))) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            await _startListening();
          },
          createRow: (_CreateRow value) {
            _rowService.createRow();
          },
          didReceiveCellDatas: (_DidReceiveCellDatas value) async {
            emit(state.copyWith(cellDataMap: value.cellData));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_rowListenFn != null) {
      _rowCache.removeRowListener(_rowListenFn!);
    }

    return super.close();
  }

  Future<void> _startListening() async {
    _rowListenFn = _rowCache.addRowListener(
      rowId: state.rowData.rowId,
      onUpdated: (cellDatas) => add(RowEvent.didReceiveCellDatas(cellDatas)),
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.didReceiveCellDatas(CellDataMap cellData) = _DidReceiveCellDatas;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required GridRow rowData,
    required CellDataMap cellDataMap,
  }) = _RowState;

  factory RowState.initial(GridRow rowData, CellDataMap cellDataMap) => RowState(
        rowData: rowData,
        cellDataMap: cellDataMap,
      );
}
