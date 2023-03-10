import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'url_cell_bloc.freezed.dart';

class URLCellBloc extends Bloc<URLCellEvent, URLCellState> {
  final URLCellController cellController;
  void Function()? _onCellChangedFn;
  URLCellBloc({
    required this.cellController,
  }) : super(URLCellState.initial(cellController)) {
    on<URLCellEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(
              content: cellData?.content ?? "",
              url: cellData?.url ?? "",
            ));
          },
          updateURL: (String url) {
            cellController.saveCellData(url, deduplicate: true);
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
          add(URLCellEvent.didReceiveCellUpdate(cellData));
        }
      }),
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
