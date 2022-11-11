import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'url_cell_editor_bloc.freezed.dart';

class URLCellEditorBloc extends Bloc<URLCellEditorEvent, URLCellEditorState> {
  final GridURLCellController cellController;
  void Function()? _onCellChangedFn;
  URLCellEditorBloc({
    required this.cellController,
  }) : super(URLCellEditorState.initial(cellController)) {
    on<URLCellEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          updateText: (text) {
            cellController.saveCellData(text, deduplicate: true);
            emit(state.copyWith(content: text));
          },
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(content: cellData?.content ?? ""));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((cellData) {
        if (!isClosed) {
          add(URLCellEditorEvent.didReceiveCellUpdate(cellData));
        }
      }),
    );
  }
}

@freezed
class URLCellEditorEvent with _$URLCellEditorEvent {
  const factory URLCellEditorEvent.initial() = _InitialCell;
  const factory URLCellEditorEvent.didReceiveCellUpdate(URLCellDataPB? cell) =
      _DidReceiveCellUpdate;
  const factory URLCellEditorEvent.updateText(String text) = _UpdateText;
}

@freezed
class URLCellEditorState with _$URLCellEditorState {
  const factory URLCellEditorState({
    required String content,
  }) = _URLCellEditorState;

  factory URLCellEditorState.initial(GridURLCellController context) {
    final cellData = context.getCellData();
    return URLCellEditorState(
      content: cellData?.content ?? "",
    );
  }
}
