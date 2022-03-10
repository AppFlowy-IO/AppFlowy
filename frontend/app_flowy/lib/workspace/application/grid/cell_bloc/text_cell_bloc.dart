import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final Field field;
  final Cell? cell;
  final CellService service;

  TextCellBloc({
    required this.field,
    required this.cell,
    required this.service,
  }) : super(TextCellState.initial(cell?.content ?? "")) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {},
          updateText: (_UpdateText value) {},
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
