import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_cell_bloc.freezed.dart';

class SummaryCellBloc extends Bloc<SummaryCellEvent, SummaryCellState> {
  SummaryCellBloc({
    required this.cellController,
  }) : super(SummaryCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final SummaryCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<SummaryCellEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(content: cellData ?? ""));
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateCell: (text) async {
            if (state.content != text) {
              emit(state.copyWith(content: text));
              await cellController.saveCellData(text);

              // If the input content is "abc" that can't parsered as number then the data stored in the backend will be an empty string.
              // So for every cell data that will be formatted in the backend.
              // It needs to get the formatted data after saving.
              add(
                SummaryCellEvent.didReceiveCellUpdate(
                  cellController.getCellData()?.content,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(SummaryCellEvent.didReceiveCellUpdate(cellContent?.content));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(SummaryCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class SummaryCellEvent with _$SummaryCellEvent {
  const factory SummaryCellEvent.didReceiveCellUpdate(String? cellContent) =
      _DidReceiveCellUpdate;
  const factory SummaryCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory SummaryCellEvent.updateCell(String text) = _UpdateCell;
}

@freezed
class SummaryCellState with _$SummaryCellState {
  const factory SummaryCellState({
    required String content,
    required bool wrap,
  }) = _SummaryCellState;

  factory SummaryCellState.initial(SummaryCellController cellController) {
    final wrap = cellController.fieldInfo.wrapCellContent;
    return SummaryCellState(
      content: cellController.getCellData()?.content ?? "",
      wrap: wrap ?? true,
    );
  }
}
