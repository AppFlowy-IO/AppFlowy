import 'dart:async';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
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

import 'board_data_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final BoardDataController _dataController;
  late final AFBoardDataController boardDataController;

  BoardBloc({required ViewPB view})
      : _dataController = BoardDataController(view: view),
        super(BoardState.initial(view.id)) {
    boardDataController = AFBoardDataController(
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
            _dataController.createRow();
          },
          didReceiveGridUpdate: (GridPB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          groupByField: (FieldPB field) {
            emit(state.copyWith(groupField: Some(field)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _dataController.dispose();
    return super.close();
  }

  GridRowCache? getRowCache(String blockId, String rowId) {
    final GridBlockCache? blockCache = _dataController.blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    _dataController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(grid));
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          _buildColumns(fields);
        }
      },
      onGroupChanged: (groups) {},
      onError: (err) {
        Log.error(err);
      },
    );
  }

  void _buildColumns(UnmodifiableListView<FieldPB> fields) {
    FieldPB? groupField;
    for (final field in fields) {
      if (field.fieldType == FieldType.SingleSelect) {
        groupField = field;
        _buildColumnsFromSingleSelect(field);
      }
    }

    assert(groupField != null);
    add(BoardEvent.groupByField(groupField!));
  }

  void _buildColumnsFromSingleSelect(FieldPB field) {
    final typeOptionContext = makeTypeOptionContext<SingleSelectTypeOptionPB>(
      gridId: _dataController.gridId,
      field: field,
    );

    typeOptionContext.loadTypeOptionData(
      onCompleted: (singleSelect) {
        List<AFBoardColumnData> columns = singleSelect.options.map((option) {
          return AFBoardColumnData(
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
    final result = await _dataController.loadData();
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
  const factory BoardEvent.groupByField(FieldPB field) = _GroupByField;
  const factory BoardEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String gridId,
    required Option<GridPB> grid,
    required Option<FieldPB> groupField,
    required List<RowInfo> rowInfos,
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
  final UnmodifiableListView<FieldPB> _fields;
  const GridFieldEquatable(
    UnmodifiableListView<FieldPB> fields,
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

  UnmodifiableListView<FieldPB> get value => UnmodifiableListView(_fields);
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
