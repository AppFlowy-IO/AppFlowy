import 'dart:collection';
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
  VoidCallback? _rowCallback;
  final String viewId;

  CardBloc({
    required this.rowMeta,
    required this.groupFieldId,
    required this.viewId,
    required RowCache rowCache,
    required bool isEditing,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowCache = rowCache,
        super(
          RowCardState.initial(
            _makeCells(groupFieldId, rowCache.loadGridCells(rowMeta)),
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
      onCellUpdated: (cellMap, reason) {
        if (!isClosed) {
          final cells = _makeCells(groupFieldId, cellMap);
          add(RowCardEvent.didReceiveCells(cells, reason));
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
    RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowCardState with _$RowCardState {
  const factory RowCardState({
    required List<DatabaseCellContext> cells,
    required bool isEditing,
    RowsChangedReason? changeReason,
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
