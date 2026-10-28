import 'dart:async';

import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_bloc.freezed.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  CardBloc({
    required this.fieldController,
    required this.groupFieldId,
    required this.viewId,
    required bool isEditing,
    required this.rowController,
    this.showAllFieldsWhenEditing = false,
  }) : super(
          CardState.initial(
            _makeCells(
              fieldController,
              groupFieldId,
              rowController,
              includeHiddenFields: showAllFieldsWhenEditing && isEditing,
            ),
            isEditing,
            rowController.rowMeta,
          ),
        ) {
    rowController.initialize();
    _dispatch();
  }

  final FieldController fieldController;
  final String? groupFieldId;
  final String viewId;
  final RowController rowController;
  final bool showAllFieldsWhenEditing;

  VoidCallback? _rowCallback;

  @override
  Future<void> close() async {
    if (_rowCallback != null) {
      _rowCallback = null;
    }
    await rowController.dispose();
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
            if (isEditing != state.isEditing) {
              emit(
                state.copyWith(
                  isEditing: isEditing,
                  cells: _makeCells(
                    fieldController,
                    groupFieldId,
                    rowController,
                    includeHiddenFields: showAllFieldsWhenEditing && isEditing,
                  ),
                ),
              );
            }
          },
          didUpdateRowMeta: (rowMeta) {
            emit(state.copyWith(rowMeta: rowMeta));
          },
        );
      },
    );
  }

  Future<void> _startListening() async {
    rowController.addListener(
      onRowChanged: (cellMap, reason) {
        if (!isClosed) {
          final List<CellMeta> cells = _makeCells(
            fieldController,
            groupFieldId,
            rowController,
            includeHiddenFields: showAllFieldsWhenEditing && state.isEditing,
          );
          add(CardEvent.didReceiveCells(cells, reason));
        }
      },
      onMetaChanged: () {
        if (!isClosed) {
          add(CardEvent.didUpdateRowMeta(rowController.rowMeta));
        }
      },
    );
  }
}

List<CellMeta> _makeCells(
  FieldController fieldController,
  String? groupFieldId,
  RowController rowController, {
  bool includeHiddenFields = false,
}) {
  // A board card's edit session exposes every field, including its group field.
  // Reading mode respects the configured visibility and column grouping.
  final cellContext = rowController.loadCells();

  cellContext.removeWhere((cellContext) {
    final fieldInfo = fieldController.getField(cellContext.fieldId);
    return fieldInfo == null ||
        (!includeHiddenFields &&
            (!(fieldInfo.visibility?.isVisibleState() ?? false) ||
                (groupFieldId != null && cellContext.fieldId == groupFieldId)));
  });
  return cellContext
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
    required bool isEditing,
    required RowMetaPB rowMeta,
    ChangedReason? changeReason,
  }) = _RowCardState;

  factory CardState.initial(
    List<CellMeta> cells,
    bool isEditing,
    RowMetaPB rowMeta,
  ) =>
      CardState(
        cells: cells,
        isEditing: isEditing,
        rowMeta: rowMeta,
      );
}
