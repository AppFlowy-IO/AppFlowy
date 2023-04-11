import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'url_cell_editor_bloc.freezed.dart';

class URLCellEditorBloc extends Bloc<URLCellEditorEvent, URLCellEditorState> {
  final URLCellController cellController;
  void Function()? _onCellChangedFn;
  URLCellEditorBloc({
    required this.cellController,
  }) : super(URLCellEditorState.initial(cellController)) {
    on<URLCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          updateText: (text) async {
            await cellController.saveCellData(text);
            emit(
              state.copyWith(
                content: text,
                isFinishEditing: true,
              ),
            );
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
    required bool isFinishEditing,
  }) = _URLCellEditorState;

  factory URLCellEditorState.initial(URLCellController context) {
    final cellData = context.getCellData();
    return URLCellEditorState(
      content: cellData?.content ?? "",
      isFinishEditing: true,
    );
  }
}
