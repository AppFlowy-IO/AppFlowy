import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_listener.dart';
import 'cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final CellService _service;
  final CellListener _cellListener;

  TextCellBloc({
    required GridCellContext cellContext,
  })  : _service = CellService(),
        _cellListener = CellListener(rowId: cellContext.rowId, fieldId: cellContext.fieldId),
        super(TextCellState.initial(cellContext.gridCell)) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          updateText: (_UpdateText value) {
            updateCellContent(value.text);
            emit(state.copyWith(content: value.text));
          },
          didReceiveCellData: (_DidReceiveCellData value) {
            emit(state.copyWith(
              cellData: value.cellData,
              content: value.cellData.cell?.content ?? "",
            ));
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(
              cellData: state.cellData.copyWith(cell: value.cell),
              content: value.cell.content,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _cellListener.stop();
    return super.close();
  }

  void updateCellContent(String content) {
    final fieldId = state.cellData.field.id;
    final gridId = state.cellData.gridId;
    final rowId = state.cellData.rowId;
    _service.updateCell(
      data: content,
      fieldId: fieldId,
      gridId: gridId,
      rowId: rowId,
    );
  }

  void _startListening() {
    _cellListener.updateCellNotifier?.addPublishListener((result) {
      result.fold(
        (notificationData) async => await _loadCellData(),
        (err) => Log.error(err),
      );
    });
    _cellListener.start();
  }

  Future<void> _loadCellData() async {
    final result = await _service.getCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (cell) => add(TextCellEvent.didReceiveCellUpdate(cell)),
      (err) => Log.error(err),
    );
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.initial() = _InitialCell;
  const factory TextCellEvent.didReceiveCellData(GridCell cellData) = _DidReceiveCellData;
  const factory TextCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
    required GridCell cellData,
  }) = _TextCellState;

  factory TextCellState.initial(GridCell cellData) => TextCellState(
        content: cellData.cell?.content ?? "",
        cellData: cellData,
      );
}
