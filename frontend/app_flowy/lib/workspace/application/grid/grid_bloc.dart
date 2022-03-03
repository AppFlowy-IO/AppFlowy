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
  late Grid _grid;

  GridBloc({required this.view, required this.service}) : super(GridState.initial()) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (Initial value) async {
            await _initial(value, emit);
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

  Future<void> _initial(Initial value, Emitter<GridState> emit) async {
    final result = await service.openGrid(gridId: view.id);
    result.fold(
      (grid) {
        _grid = grid;
        _loadGridInfo(emit);
      },
      (err) {
        emit(state.copyWith(loadingState: GridLoadingState.finish(right(err))));
      },
    );
  }

  Future<void> _loadGridInfo(Emitter<GridState> emit) async {
    emit(
      state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
    );
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

typedef FieldById = Map<String, Field>;
typedef RowById = Map<String, Row>;
typedef CellById = Map<String, DisplayCell>;

class GridInfo {
  List<RowOrder> rowOrders;
  List<FieldOrder> fieldOrders;
  RowById rowMap;
  FieldById fieldMap;

  GridInfo({
    required this.rowOrders,
    required this.fieldOrders,
    required this.fieldMap,
    required this.rowMap,
  });

  RowInfo rowInfoAtIndex(int index) {
    final rowOrder = rowOrders[index];
    final Row row = rowMap[rowOrder.rowId]!;
    final cellMap = row.cellByFieldId;

    final displayCellMap = <String, DisplayCell>{};

    return RowInfo(
      fieldOrders: fieldOrders,
      fieldMap: fieldMap,
      displayCellMap: displayCellMap,
    );
  }

  int numberOfRows() {
    return rowOrders.length;
  }
}

class RowInfo {
  List<FieldOrder> fieldOrders;
  FieldById fieldMap;
  CellById displayCellMap;
  RowInfo({
    required this.fieldOrders,
    required this.fieldMap,
    required this.displayCellMap,
  });
}
