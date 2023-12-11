import 'dart:collection';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/cell/cell_service.dart';
import '../../../application/row/row_cache.dart';
import '../../../application/row/row_controller.dart';
import '../../../application/row/row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowBackendService _rowBackendSvc;
  final RowController _dataController;
  final RowListener _rowListener;
  final String viewId;
  final String rowId;

  RowBloc({
    required this.rowId,
    required this.viewId,
    required RowController dataController,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _dataController = dataController,
        _rowListener = RowListener(rowId),
        super(RowState.initial(dataController.loadData())) {
    on<RowEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          createRow: () {
            _rowBackendSvc.createRowAfter(rowId);
          },
          didReceiveCells: (cellByFieldId, reason) async {
            cellByFieldId
                .removeWhere((_, cellContext) => !cellContext.isVisible());
            final cells = cellByFieldId.values
                .map((e) => GridCellEquatable(e.fieldInfo))
                .toList();
            emit(
              state.copyWith(
                cellByFieldId: cellByFieldId,
                cells: UnmodifiableListView(cells),
                changeReason: reason,
              ),
            );
          },
          reloadRow: (DidFetchRowPB row) {
            emit(state.copyWith(rowSource: RowSourece.remote(row)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _dataController.dispose();
    await _rowListener.stop();
    return super.close();
  }

  Future<void> _startListening() async {
    _dataController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(RowEvent.didReceiveCells(cells, reason));
        }
      },
    );

    _rowListener.start(
      onRowFetched: (fetchRow) {
        if (!isClosed) {
          add(RowEvent.reloadRow(fetchRow));
        }
      },
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.reloadRow(DidFetchRowPB row) = _ReloadRow;
  const factory RowEvent.didReceiveCells(
    CellContextByFieldId cellsByFieldId,
    ChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required CellContextByFieldId cellByFieldId,
    required UnmodifiableListView<GridCellEquatable> cells,
    required RowSourece rowSource,
    ChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial(
    CellContextByFieldId cellByFieldId,
  ) {
    cellByFieldId.removeWhere((_, cellContext) => !cellContext.isVisible());
    return RowState(
      cellByFieldId: cellByFieldId,
      cells: UnmodifiableListView(
        cellByFieldId.values
            .map((e) => GridCellEquatable(e.fieldInfo))
            .toList(),
      ),
      rowSource: const RowSourece.disk(),
    );
  }
}

class GridCellEquatable extends Equatable {
  final FieldInfo _fieldInfo;

  const GridCellEquatable(FieldInfo field) : _fieldInfo = field;

  @override
  List<Object?> get props => [
        _fieldInfo.id,
        _fieldInfo.fieldType,
        _fieldInfo.field.visibility,
        _fieldInfo.fieldSettings?.width,
      ];
}

@freezed
class RowSourece with _$RowSourece {
  const factory RowSourece.disk() = _Disk;
  const factory RowSourece.remote(
    DidFetchRowPB row,
  ) = _Remote;
}
