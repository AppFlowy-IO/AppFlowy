import 'dart:collection';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_service.dart';
import 'package:dartz/dartz.dart';

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
          },
          didReceiveCellDatas: (_DidReceiveCellDatas value) {},
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
      rowId: rowData.rowId,
      onUpdated: (cellDatas) => add(RowDetailEvent.didReceiveCellDatas(cellDatas)),
      listenWhen: () => !isClosed,
    );
  }

  Future<void> _loadRow(Emitter<RowDetailState> emit) async {
    final data = _rowCache.loadCellData(rowData.rowId);
    data.foldRight(null, (cellDatas, _) {
      if (!isClosed) {
        add(RowDetailEvent.didReceiveCellDatas(cellDatas));
      }
    });
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.didReceiveCellDatas(CellDataMap cellData) = _DidReceiveCellDatas;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required Option<CellDataMap> cellDataMap,
  }) = _RowDetailState;

  factory RowDetailState.initial() => RowDetailState(
        cellDataMap: none(),
      );
}
