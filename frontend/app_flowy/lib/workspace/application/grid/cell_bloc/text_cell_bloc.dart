import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final CellService service;

  TextCellBloc({
    required this.service,
    required FutureCellData cellData,
  }) : super(TextCellState.initial(cellData)) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {},
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
        );
      },
    );
  }

  void updateCellContent(String content) {
    final fieldId = state.cellData.field.id;
    final gridId = state.cellData.gridId;
    final rowId = state.cellData.rowId;
    service.updateCell(
      data: content,
      fieldId: fieldId,
      gridId: gridId,
      rowId: rowId,
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.initial() = _InitialCell;
  const factory TextCellEvent.didReceiveCellData(GridCellData cellData) = _DidReceiveCellData;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
    required FutureCellData cellData,
  }) = _TextCellState;

  factory TextCellState.initial(FutureCellData cellData) => TextCellState(
        content: cellData.cell?.content ?? "",
        cellData: cellData,
      );
}
