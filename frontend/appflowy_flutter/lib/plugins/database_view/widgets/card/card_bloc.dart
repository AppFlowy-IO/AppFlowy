import 'dart:collection';
import 'package:appflowy/plugins/database_view/application/row/row_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../application/cell/cell_service.dart';
import '../../application/row/row_cache.dart';
import '../../application/row/row_service.dart';

part 'card_bloc.freezed.dart';

class CardBloc extends Bloc<RowCardEvent, RowCardState> {
  final RowMetaPB rowMeta;
  final String? groupFieldId;
  final RowBackendService _rowBackendSvc;
  final RowCache _rowCache;
  final String viewId;
  final RowListener _rowListener;

  VoidCallback? _rowCallback;

  CardBloc({
    required this.rowMeta,
    required this.groupFieldId,
    required this.viewId,
    required RowCache rowCache,
    required bool isEditing,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowListener = RowListener(rowMeta.id),
        _rowCache = rowCache,
        super(
          RowCardState.initial(
            _makeCells(groupFieldId, rowCache.loadCells(rowMeta)),
            isEditing,
          ),
        ) {
    on<RowCardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          didReceiveCells: (cells, reason) async {
            emit(
              state.copyWith(
                cells: cells,
                changeReason: reason,
              ),
            );
          },
          setIsEditing: (bool isEditing) {
            emit(state.copyWith(isEditing: isEditing));
          },
          didReceiveRowMeta: (rowMeta) {
            final cells = state.cells
                .map(
                  (cell) => cell.rowMeta.id == rowMeta.id
                      ? cell.copyWith(rowMeta: rowMeta)
                      : cell,
                )
                .toList();
            emit(state.copyWith(cells: cells));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_rowCallback != null) {
      _rowCache.removeRowListener(_rowCallback!);
      _rowCallback = null;
    }
    return super.close();
  }

  RowInfo rowInfo() {
    return RowInfo(
      viewId: _rowBackendSvc.viewId,
      fields: UnmodifiableListView(
        state.cells.map((cell) => cell.fieldInfo).toList(),
      ),
      rowId: rowMeta.id,
      rowMeta: rowMeta,
    );
  }

  Future<void> _startListening() async {
    _rowCallback = _rowCache.addListener(
      rowId: rowMeta.id,
      onRowChanged: (cellMap, reason) {
        if (!isClosed) {
          final cells = _makeCells(groupFieldId, cellMap);
          add(RowCardEvent.didReceiveCells(cells, reason));
        }
      },
    );

    _rowListener.start(
      onMetaChanged: (meta) {
        if (!isClosed) {
          add(RowCardEvent.didReceiveRowMeta(meta));
        }
      },
    );
  }
}

List<DatabaseCellContext> _makeCells(
  String? groupFieldId,
  CellContextByFieldId originalCellMap,
) {
  final List<DatabaseCellContext> cells = [];
  originalCellMap
      .removeWhere((fieldId, cellContext) => !cellContext.isVisible());
  for (final entry in originalCellMap.entries) {
    // Filter out the cell if it's fieldId equal to the groupFieldId
    if (groupFieldId != null) {
      if (entry.value.fieldId == groupFieldId) {
        continue;
      }
    }

    cells.add(entry.value);
  }
  return cells;
}

@freezed
class RowCardEvent with _$RowCardEvent {
  const factory RowCardEvent.initial() = _InitialRow;
  const factory RowCardEvent.setIsEditing(bool isEditing) = _IsEditing;
  const factory RowCardEvent.didReceiveCells(
    List<DatabaseCellContext> cells,
    ChangedReason reason,
  ) = _DidReceiveCells;
  const factory RowCardEvent.didReceiveRowMeta(
    RowMetaPB meta,
  ) = _DidReceiveRowMeta;
}

@freezed
class RowCardState with _$RowCardState {
  const factory RowCardState({
    required List<DatabaseCellContext> cells,
    required bool isEditing,
    ChangedReason? changeReason,
  }) = _RowCardState;

  factory RowCardState.initial(
    List<DatabaseCellContext> cells,
    bool isEditing,
  ) =>
      RowCardState(
        cells: cells,
        isEditing: isEditing,
      );
}
