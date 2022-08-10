import 'dart:async';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:collection';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final GridDataController _gridDataController;
  late final BoardDataController boardDataController;

  BoardBloc({required ViewPB view})
      : _gridDataController = GridDataController(view: view),
        super(BoardState.initial(view.id)) {
    boardDataController = BoardDataController(
      onMoveColumn: (
        fromIndex,
        toIndex,
      ) {},
      onMoveColumnItem: (
        columnId,
        fromIndex,
        toIndex,
      ) {},
      onMoveColumnItemToColumn: (
        fromColumnId,
        fromIndex,
        toColumnId,
        toIndex,
      ) {},
    );

    // boardDataController.addColumns(_buildColumns());

    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadGrid(emit);
          },
          createRow: () {
            _gridDataController.createRow();
          },
          didReceiveGridUpdate: (GridPB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridDataController.dispose();
    return super.close();
  }

  GridRowCache? getRowCache(String blockId, String rowId) {
    final GridBlockCache? blockCache = _gridDataController.blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    _gridDataController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(grid));
        }
      },
      onRowsChanged: (rowInfos, reason) {
        if (!isClosed) {
          _buildColumnItems(rowInfos);
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          _buildColumns(fields);
        }
      },
    );
  }

  void _buildColumnItems(List<GridRowInfo> rowInfos) {
    for (final rowInfo in rowInfos) {}
  }

  void _buildColumns(UnmodifiableListView<GridFieldPB> fields) {
    for (final field in fields) {
      if (field.fieldType == FieldType.SingleSelect) {
        _buildColumnsFromSingleSelect(field);
      }
    }
  }

  void _buildColumnsFromSingleSelect(GridFieldPB field) {
    final typeOptionContext = makeTypeOptionContext<SingleSelectTypeOptionPB>(
      gridId: _gridDataController.gridId,
      field: field,
    );

    typeOptionContext.loadTypeOptionData(
      onCompleted: (singleSelect) {
        List<BoardColumnData> columns = singleSelect.options.map((option) {
          return BoardColumnData(
            id: option.id,
            desc: option.name,
            customData: option,
          );
        }).toList();

        boardDataController.addColumns(columns);
      },
      onError: (err) => Log.error(err),
    );
  }

  Future<void> _loadGrid(Emitter<BoardState> emit) async {
    final result = await _gridDataController.loadData();
    result.fold(
      (grid) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
      ),
      (err) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err))),
      ),
    );
  }
}

@freezed
class BoardEvent with _$BoardEvent {
  const factory BoardEvent.initial() = InitialGrid;
  const factory BoardEvent.createRow() = _CreateRow;
  const factory BoardEvent.groupByField(GridFieldPB field) = _GroupByField;
  const factory BoardEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String gridId,
    required Option<GridPB> grid,
    required Option<GridFieldPB> groupField,
    required List<GridRowInfo> rowInfos,
    required GridLoadingState loadingState,
  }) = _BoardState;

  factory BoardState.initial(String gridId) => BoardState(
        rowInfos: [],
        groupField: none(),
        grid: none(),
        gridId: gridId,
        loadingState: const _Loading(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(
      Either<Unit, FlowyError> successOrFail) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final UnmodifiableListView<GridFieldPB> _fields;
  const GridFieldEquatable(
    UnmodifiableListView<GridFieldPB> fields,
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

  UnmodifiableListView<GridFieldPB> get value => UnmodifiableListView(_fields);
}

class TextItem extends ColumnItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}

class RichTextItem extends ColumnItem {
  final String title;
  final String subtitle;

  RichTextItem({required this.title, required this.subtitle});

  @override
  String get id => title;
}
