import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'field/field_controller.dart';
import 'grid_data_controller.dart';
import 'row/row_cache.dart';
import 'dart:collection';

import 'row/row_service.dart';
part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridController gridController;
  void Function()? _createRowOperation;

  GridBloc({required ViewPB view, required this.gridController})
      : super(GridState.initial(view.id)) {
    on<GridEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openGrid(emit);
          },
          createRow: () {
            state.loadingState.when(
              loading: () {
                _createRowOperation = () => gridController.createRow();
              },
              finish: (_) => gridController.createRow(),
            );
          },
          deleteRow: (rowInfo) async {
            final rowService = RowFFIService(
              gridId: rowInfo.gridId,
            );
            await rowService.deleteRow(rowInfo.rowPB.id);
          },
          didReceiveGridUpdate: (grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveFieldUpdate: (fields) {
            emit(state.copyWith(
              fields: GridFieldEquatable(fields),
            ));
          },
          didReceiveRowUpdate: (newRowInfos, reason) {
            emit(state.copyWith(
              rowInfos: newRowInfos,
              rowCount: newRowInfos.length,
              reason: reason,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await gridController.dispose();
    return super.close();
  }

  GridRowCache? getRowCache(String blockId, String rowId) {
    return gridController.rowCache;
  }

  void _startListening() {
    gridController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(GridEvent.didReceiveGridUpdate(grid));
        }
      },
      onRowsChanged: (rowInfos, reason) {
        if (!isClosed) {
          add(GridEvent.didReceiveRowUpdate(rowInfos, reason));
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          add(GridEvent.didReceiveFieldUpdate(fields));
        }
      },
    );
  }

  Future<void> _openGrid(Emitter<GridState> emit) async {
    final result = await gridController.openGrid();
    result.fold(
      (grid) {
        if (_createRowOperation != null) {
          _createRowOperation?.call();
          _createRowOperation = null;
        }
        emit(
          state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
        );
      },
      (err) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err))),
      ),
    );
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.deleteRow(RowInfo rowInfo) = _DeleteRow;
  const factory GridEvent.didReceiveRowUpdate(
    List<RowInfo> rows,
    RowsChangedReason listState,
  ) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;

  const factory GridEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String gridId,
    required Option<GridPB> grid,
    required GridFieldEquatable fields,
    required List<RowInfo> rowInfos,
    required int rowCount,
    required GridLoadingState loadingState,
    required RowsChangedReason reason,
  }) = _GridState;

  factory GridState.initial(String gridId) => GridState(
        fields: GridFieldEquatable(UnmodifiableListView([])),
        rowInfos: [],
        rowCount: 0,
        grid: none(),
        gridId: gridId,
        loadingState: const _Loading(),
        reason: const InitialListState(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(
      Either<Unit, FlowyError> successOrFail) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final List<FieldInfo> _fields;
  const GridFieldEquatable(
    List<FieldInfo> fields,
  ) : _fields = fields;

  @override
  List<Object?> get props {
    if (_fields.isEmpty) {
      return [];
    }

    return [
      _fields.length,
      _fields
          .map((field) => field.width)
          .reduce((value, element) => value + element),
    ];
  }

  UnmodifiableListView<FieldInfo> get value => UnmodifiableListView(_fields);
}
