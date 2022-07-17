import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_service.dart';

part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final GridRow rowData;
  final GridRowCache _rowCache;
  void Function()? _rowListenFn;

  RowDetailBloc({
    required this.rowData,
    required GridRowCache rowCache,
  })  : _rowCache = rowCache,
        super(RowDetailState.initial()) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            await _startListening();
            _loadCellData();
          },
          didReceiveCellDatas: (_DidReceiveCellDatas value) {
            emit(state.copyWith(gridCells: value.gridCells));
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
    _rowListenFn = _rowCache.addListener(
      rowId: rowData.id,
      onCellUpdated: (cellDatas, reason) => add(RowDetailEvent.didReceiveCellDatas(cellDatas.values.toList())),
      listenWhen: () => !isClosed,
    );
  }

  Future<void> _loadCellData() async {
    final cellDataMap = _rowCache.loadGridCells(rowData.id);
    if (!isClosed) {
      add(RowDetailEvent.didReceiveCellDatas(cellDataMap.values.toList()));
    }
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.didReceiveCellDatas(List<GridCellIdentifier> gridCells) = _DidReceiveCellDatas;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required List<GridCellIdentifier> gridCells,
  }) = _RowDetailState;

  factory RowDetailState.initial() => RowDetailState(
        gridCells: List.empty(),
      );
}
