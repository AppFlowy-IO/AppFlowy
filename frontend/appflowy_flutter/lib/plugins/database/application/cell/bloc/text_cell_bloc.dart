import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  TextCellBloc({required this.cellController})
      : super(TextCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TextCellController cellController;
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
    on<TextCellEvent>(
      (event, emit) {
        event.when(
          didReceiveCellUpdate: (String content) {
            emit(state.copyWith(content: content));
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          didUpdateEmoji: (String emoji, bool hasDocument) {
            // emit(state.copyWith(emoji: emoji, hasDocument: hasDocument));
          },
          updateText: (String text) {
            if (state.content != text) {
              cellController.saveCellData(text, debounce: true);
            }
          },
          enableEdit: (bool enabled) {
            emit(state.copyWith(enableEdit: enabled));
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(TextCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TextCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
  const factory TextCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
  const factory TextCellEvent.enableEdit(bool enabled) = _EnableEdit;
  const factory TextCellEvent.didUpdateEmoji(
    String emoji,
    bool hasDocument,
  ) = _UpdateEmoji;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
    required ValueNotifier<String>? emoji,
    required ValueNotifier<bool>? hasDocument,
    required bool enableEdit,
    required bool wrap,
  }) = _TextCellState;

  factory TextCellState.initial(TextCellController cellController) {
    final cellData = cellController.getCellData() ?? "";
    final wrap = cellController.fieldInfo.wrapCellContent ?? true;
    ValueNotifier<String>? emoji;
    if (cellController.fieldInfo.isPrimary) {
      emoji = cellController.icon;
    }

    return TextCellState(
      content: cellData,
      emoji: emoji,
      enableEdit: false,
      hasDocument: cellController.hasDocument,
      wrap: wrap,
    );
  }
}
