import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/type_option/relation_type_option_cubit.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_cell_bloc.freezed.dart';

class RelationCellBloc extends Bloc<RelationCellEvent, RelationCellState> {
  RelationCellBloc({required this.cellController})
      : super(RelationCellState.initial()) {
    _dispatch();
    _startListening();
    _init();
  }

  final RelationCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    return super.close();
  }

  void _dispatch() {
    on<RelationCellEvent>(
      (event, emit) async {
        await event.when(
          didUpdateCell: (RelationCellDataPB? cellData) async {
            if (cellData == null ||
                cellData.rowIds.isEmpty ||
                state.relatedDatabaseMeta == null) {
              emit(state.copyWith(rows: const []));
              return;
            }
            final payload = RepeatedRowIdPB(
              databaseId: state.relatedDatabaseMeta!.databaseId,
              rowIds: cellData.rowIds,
            );
            final result =
                await DatabaseEventGetRelatedRowDatas(payload).send();
            final rows = result.fold(
              (data) => data.rows,
              (err) {
                Log.error(err);
                return const <RelatedRowDataPB>[];
              },
            );
            emit(state.copyWith(rows: rows));
          },
          didUpdateRelationTypeOption: (typeOption) async {
            if (typeOption.databaseId.isEmpty) {
              return;
            }
            final meta = await _loadDatabaseMeta(typeOption.databaseId);
            emit(state.copyWith(relatedDatabaseMeta: meta));
            _loadCellData();
          },
          selectDatabaseId: (databaseId) async {
            await _updateTypeOption(databaseId);
          },
          selectRow: (rowId) async {
            await _handleSelectRow(rowId);
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(RelationCellEvent.didUpdateCell(data));
        }
      },
      onCellFieldChanged: (field) {
        // hack: SingleFieldListener receives notification before
        // FieldController's copy is updated.
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!isClosed) {
            final RelationTypeOptionPB typeOption =
                cellController.getTypeOption(RelationTypeOptionDataParser());
            add(RelationCellEvent.didUpdateRelationTypeOption(typeOption));
          }
        });
      },
    );
  }

  void _init() {
    final typeOption =
        cellController.getTypeOption(RelationTypeOptionDataParser());
    add(RelationCellEvent.didUpdateRelationTypeOption(typeOption));
  }

  void _loadCellData() {
    final cellData = cellController.getCellData();
    if (!isClosed) {
      add(RelationCellEvent.didUpdateCell(cellData));
    }
  }

  Future<void> _handleSelectRow(String rowId) async {
    final payload = RelationCellChangesetPB(
      viewId: cellController.viewId,
      cellId: CellIdPB(
        viewId: cellController.viewId,
        fieldId: cellController.fieldId,
        rowId: cellController.rowId,
      ),
    );
    if (state.rows.any((row) => row.rowId == rowId)) {
      payload.removedRowIds.add(rowId);
    } else {
      payload.insertedRowIds.add(rowId);
    }
    final result = await DatabaseEventUpdateRelationCell(payload).send();
    result.fold((l) => null, (err) => Log.error(err));
  }

  Future<DatabaseMeta?> _loadDatabaseMeta(String databaseId) async {
    final getDatabaseResult = await DatabaseEventGetDatabases().send();
    final databaseMeta = getDatabaseResult.fold<DatabaseMetaPB?>(
      (s) => s.items.firstWhereOrNull(
        (metaPB) => metaPB.databaseId == databaseId,
      ),
      (f) => null,
    );
    if (databaseMeta != null) {
      final result =
          await ViewBackendService.getView(databaseMeta.inlineViewId);
      return result.fold(
        (s) => DatabaseMeta(
          databaseId: databaseId,
          inlineViewId: databaseMeta.inlineViewId,
          databaseName: s.name,
        ),
        (f) => null,
      );
    }
    return null;
  }

  Future<void> _updateTypeOption(String databaseId) async {
    final newDateTypeOption = RelationTypeOptionPB(
      databaseId: databaseId,
    );

    final result = await FieldBackendService.updateFieldTypeOption(
      viewId: cellController.viewId,
      fieldId: cellController.fieldInfo.id,
      typeOptionData: newDateTypeOption.writeToBuffer(),
    );
    result.fold((s) => null, (err) => Log.error(err));
  }
}

@freezed
class RelationCellEvent with _$RelationCellEvent {
  const factory RelationCellEvent.didUpdateRelationTypeOption(
    RelationTypeOptionPB typeOption,
  ) = _DidUpdateRelationTypeOption;
  const factory RelationCellEvent.didUpdateCell(RelationCellDataPB? data) =
      _DidUpdateCell;
  const factory RelationCellEvent.selectDatabaseId(
    String databaseId,
  ) = _SelectDatabaseId;
  const factory RelationCellEvent.selectRow(String rowId) = _SelectRowId;
}

@freezed
class RelationCellState with _$RelationCellState {
  const factory RelationCellState({
    required DatabaseMeta? relatedDatabaseMeta,
    required List<RelatedRowDataPB> rows,
  }) = _RelationCellState;

  factory RelationCellState.initial() => const RelationCellState(
        relatedDatabaseMeta: null,
        rows: [],
      );
}
