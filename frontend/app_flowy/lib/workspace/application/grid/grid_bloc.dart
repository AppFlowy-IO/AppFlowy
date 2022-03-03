import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'grid_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridService service;
  final View view;
  late Grid? _grid;
  late List<Field>? _fields;

  GridBloc({required this.view, required this.service}) : super(GridState.initial()) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (Initial value) async {
            await _loadGrid(emit);
            await _loadFields(emit);
            await _loadGridInfo(emit);
          },
          createRow: (_CreateRow value) {
            service.createRow(gridId: view.id);
          },
          delete: (_Delete value) {},
          rename: (_Rename value) {},
          updateDesc: (_Desc value) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await service.openGrid(gridId: view.id);
    result.fold(
      (grid) {
        _grid = grid;
      },
      (err) {
        emit(state.copyWith(loadingState: GridLoadingState.finish(right(err))));
      },
    );
  }

  Future<void> _loadFields(Emitter<GridState> emit) async {
    if (_grid != null) {
      final result = await service.getFields(fieldOrders: _grid!.fieldOrders);
      result.fold(
        (fields) {
          _fields = fields.items;
        },
        (err) {
          emit(state.copyWith(loadingState: GridLoadingState.finish(right(err))));
        },
      );
    }
  }

  Future<void> _loadGridInfo(Emitter<GridState> emit) async {
    if (_grid != null && _fields != null) {
      final result = await service.getRows(rowOrders: _grid!.rowOrders);
      result.fold((repeatedRow) {
        final rows = repeatedRow.items;
        final gridInfo = GridInfo(rows: rows, fields: _fields!);

        emit(
          state.copyWith(loadingState: GridLoadingState.finish(left(unit)), gridInfo: some(left(gridInfo))),
        );
      }, (err) {
        emit(
          state.copyWith(loadingState: GridLoadingState.finish(right(err)), gridInfo: none()),
        );
      });
    }
  }
}

@freezed
abstract class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = Initial;
  const factory GridEvent.rename(String gridId, String name) = _Rename;
  const factory GridEvent.updateDesc(String gridId, String desc) = _Desc;
  const factory GridEvent.delete(String gridId) = _Delete;
  const factory GridEvent.createRow() = _CreateRow;
}

@freezed
abstract class GridState with _$GridState {
  const factory GridState({
    required GridLoadingState loadingState,
    required Option<Either<GridInfo, FlowyError>> gridInfo,
  }) = _GridState;

  factory GridState.initial() => GridState(
        loadingState: const _Loading(),
        gridInfo: none(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}

class GridInfo {
  List<GridRow> rows;
  List<Field> fields;

  GridInfo({
    required this.rows,
    required this.fields,
  });

  RowInfo rowInfoAtIndex(int index) {
    final row = rows[index];
    return RowInfo(
      fields: fields,
      cellMap: row.cellByFieldId,
    );
  }

  int numberOfRows() {
    return rows.length;
  }
}

class RowInfo {
  List<Field> fields;
  Map<String, GridCell> cellMap;
  RowInfo({
    required this.fields,
    required this.cellMap,
  });
}
