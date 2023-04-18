import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'url_card_cell_bloc.freezed.dart';

class URLCardCellBloc extends Bloc<URLCardCellEvent, URLCardCellState> {
  final URLCellController cellController;
  void Function()? _onCellChangedFn;
  URLCardCellBloc({
    required this.cellController,
  }) : super(URLCardCellState.initial(cellController)) {
    on<URLCardCellEvent>(
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
          add(URLCardCellEvent.didReceiveCellUpdate(cellData));
        }
      }),
    );
  }
}

@freezed
class URLCardCellEvent with _$URLCardCellEvent {
  const factory URLCardCellEvent.initial() = _InitialCell;
  const factory URLCardCellEvent.updateURL(String url) = _UpdateURL;
  const factory URLCardCellEvent.didReceiveCellUpdate(URLCellDataPB? cell) =
      _DidReceiveCellUpdate;
}

@freezed
class URLCardCellState with _$URLCardCellState {
  const factory URLCardCellState({
    required String content,
    required String url,
  }) = _URLCardCellState;

  factory URLCardCellState.initial(URLCellController context) {
    final cellData = context.getCellData();
    return URLCardCellState(
      content: cellData?.content ?? "",
      url: cellData?.url ?? "",
    );
  }
}
