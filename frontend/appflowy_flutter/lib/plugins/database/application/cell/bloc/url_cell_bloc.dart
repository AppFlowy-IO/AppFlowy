import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_cell_bloc.freezed.dart';

class URLCellBloc extends Bloc<URLCellEvent, URLCellState> {
  URLCellBloc({required this.cellController})
      : super(URLCellState.initial(cellController)) {
    _dispatch();
  }

  final URLCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<URLCellEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (cellData) {
            emit(
              state.copyWith(
                content: cellData?.content ?? "",
                url: cellData?.url ?? "",
              ),
            );
          },
          updateURL: (String url) {
            cellController.saveCellData(url, debounce: true);
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellData) {
        if (!isClosed) {
          add(URLCellEvent.didReceiveCellUpdate(cellData));
        }
      },
    );
  }
}

@freezed
class URLCellEvent with _$URLCellEvent {
  const factory URLCellEvent.initial() = _InitialCell;
  const factory URLCellEvent.updateURL(String url) = _UpdateURL;
  const factory URLCellEvent.didReceiveCellUpdate(URLCellDataPB? cell) =
      _DidReceiveCellUpdate;
}

@freezed
class URLCellState with _$URLCellState {
  const factory URLCellState({
    required String content,
    required String url,
  }) = _URLCellState;

  factory URLCellState.initial(URLCellController context) {
    final cellData = context.getCellData();
    return URLCellState(
      content: cellData?.content ?? "",
      url: cellData?.url ?? "",
    );
  }
}
