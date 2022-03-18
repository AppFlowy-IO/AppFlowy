import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final CellService service;

  TextCellBloc({
    required this.service,
  }) : super(TextCellState.initial(service.context.cell?.content ?? "")) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {},
          updateText: (_UpdateText value) {
            service.updateCell(data: value.text);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
abstract class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.initial() = _InitialCell;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
}

@freezed
abstract class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
  }) = _TextCellState;

  factory TextCellState.initial(String content) => TextCellState(content: content);
}
