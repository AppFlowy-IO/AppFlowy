import 'dart:collection';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../application/cell/cell_service.dart';
import '../../application/row/row_cache.dart';
import '../../application/row/row_service.dart';

part 'card_bloc.freezed.dart';

class CardBloc extends Bloc<RowCardEvent, RowCardState> {
  final RowPB row;
  final String? groupFieldId;
  final RowBackendService _rowBackendSvc;
  final RowCache _rowCache;
  VoidCallback? _rowCallback;

  CardBloc({
    required this.row,
    required this.groupFieldId,
    required final String viewId,
    required final RowCache rowCache,
    required final bool isEditing,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowCache = rowCache,
        super(
          RowCardState.initial(
            row,
            _makeCells(groupFieldId, rowCache.loadGridCells(row.id)),
            isEditing,
          ),
        ) {
    on<RowCardEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          didReceiveCells: (final cells, final reason) async {
            emit(
              state.copyWith(
                cells: cells,
                changeReason: reason,
              ),
            );
          },
          setIsEditing: (final bool isEditing) {
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
        state.cells.map((final cell) => cell.fieldInfo).toList(),
      ),
      rowPB: state.rowPB,
    );
  }

  Future<void> _startListening() async {
    _rowCallback = _rowCache.addListener(
      rowId: row.id,
      onCellUpdated: (final cellMap, final reason) {
        if (!isClosed) {
          final cells = _makeCells(groupFieldId, cellMap);
          add(RowCardEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }
}

List<CellIdentifier> _makeCells(
  final String? groupFieldId,
  final CellByFieldId originalCellMap,
) {
  final List<CellIdentifier> cells = [];
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
  const factory RowCardEvent.setIsEditing(final bool isEditing) = _IsEditing;
  const factory RowCardEvent.didReceiveCells(
    final List<CellIdentifier> cells,
    final RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowCardState with _$RowCardState {
  const factory RowCardState({
    required final RowPB rowPB,
    required final List<CellIdentifier> cells,
    required final bool isEditing,
    final RowsChangedReason? changeReason,
  }) = _RowCardState;

  factory RowCardState.initial(
    final RowPB rowPB,
    final List<CellIdentifier> cells,
    final bool isEditing,
  ) =>
      RowCardState(
        rowPB: rowPB,
        cells: cells,
        isEditing: isEditing,
      );
}
