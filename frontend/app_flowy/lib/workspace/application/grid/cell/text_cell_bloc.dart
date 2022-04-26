import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final GridDefaultCellContext cellContext;
  void Function()? _onCellChangedFn;
  TextCellBloc({
    required this.cellContext,
  }) : super(TextCellState.initial(cellContext)) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          updateText: (_UpdateText value) {
            cellContext.saveCellData(value.text);
            emit(state.copyWith(content: value.text));
          },
          didReceiveCellData: (_DidReceiveCellData value) {
            emit(state.copyWith(content: value.cellData.cell?.content ?? ""));
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(
              content: value.cell.content,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
      onCellChanged: ((cell) {
        if (!isClosed) {
          add(TextCellEvent.didReceiveCellUpdate(cell));
        }
      }),
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
  }) = _TextCellState;

  factory TextCellState.initial(GridDefaultCellContext context) => TextCellState(
        content: context.getCellData()?.content ?? "",
      );
}
