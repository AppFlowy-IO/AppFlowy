import 'dart:async';

import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/domain/row_listener.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_bloc.freezed.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  CardBloc({
    required this.fieldController,
    required this.groupFieldId,
    required this.viewId,
    required RowMetaPB rowMeta,
    required RowCache rowCache,
    required bool isEditing,
  })  : rowId = rowMeta.id,
        _rowListener = RowListener(rowMeta.id),
        _rowCache = rowCache,
        super(
          CardState.initial(
            rowMeta,
            _makeCells(
              fieldController,
              groupFieldId,
              rowCache.loadCells(rowMeta),
            ),
            isEditing,
          ),
        ) {
    _dispatch();
  }

  final FieldController fieldController;
  final String rowId;
  final String? groupFieldId;
  final RowCache _rowCache;
  final String viewId;
  final RowListener _rowListener;

  VoidCallback? _rowCallback;

  @override
  Future<void> close() async {
    if (_rowCallback != null) {
      _rowCache.removeRowListener(_rowCallback!);
      _rowCallback = null;
    }
    await _rowListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<CardEvent>(
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
          didUpdateRowMeta: (rowMeta) {
            emit(state.copyWith(rowMeta: rowMeta));
          },
        );
      },
    );
  }

  Future<void> _startListening() async {
    _rowCallback = _rowCache.addListener(
      rowId: rowId,
      onRowChanged: (cellMap, reason) {
        if (!isClosed) {
          final cells = _makeCells(fieldController, groupFieldId, cellMap);
          add(CardEvent.didReceiveCells(cells, reason));
        }
      },
    );

    _rowListener.start(
      onMetaChanged: (rowMeta) {
        if (!isClosed) {
          add(CardEvent.didUpdateRowMeta(rowMeta));
        }
      },
    );
  }
}

List<CellMeta> _makeCells(
  FieldController fieldController,
  String? groupFieldId,
  List<CellContext> cellContexts,
) {
  // Only show the non-hidden cells and cells that aren't of the grouping field
  cellContexts.removeWhere((cellContext) {
    final fieldInfo = fieldController.getField(cellContext.fieldId);
    return fieldInfo == null ||
        !(fieldInfo.visibility?.isVisibleState() ?? false) ||
        (groupFieldId != null && cellContext.fieldId == groupFieldId);
  });
  return cellContexts
      .map(
        (cellCtx) => CellMeta(
          fieldId: cellCtx.fieldId,
          rowId: cellCtx.rowId,
          fieldType: fieldController.getField(cellCtx.fieldId)!.fieldType,
        ),
      )
      .toList();
}

@freezed
class CardEvent with _$CardEvent {
  const factory CardEvent.initial() = _InitialRow;
  const factory CardEvent.setIsEditing(bool isEditing) = _IsEditing;
  const factory CardEvent.didReceiveCells(
    List<CellMeta> cells,
    ChangedReason reason,
  ) = _DidReceiveCells;
  const factory CardEvent.didUpdateRowMeta(RowMetaPB rowMeta) =
      _DidUpdateRowMeta;
}

@freezed
class CellMeta with _$CellMeta {
  const CellMeta._();

  const factory CellMeta({
    required String fieldId,
    required RowId rowId,
    required FieldType fieldType,
  }) = _DatabaseCellMeta;

  CellContext cellContext() => CellContext(fieldId: fieldId, rowId: rowId);
}

@freezed
class CardState with _$CardState {
  const factory CardState({
    required List<CellMeta> cells,
    required RowMetaPB rowMeta,
    required bool isEditing,
    ChangedReason? changeReason,
  }) = _RowCardState;

  factory CardState.initial(
    RowMetaPB rowMeta,
    List<CellMeta> cells,
    bool isEditing,
  ) =>
      CardState(
        cells: cells,
        rowMeta: rowMeta,
        isEditing: isEditing,
      );
}
