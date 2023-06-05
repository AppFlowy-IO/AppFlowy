import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option_entities.pb.dart';
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
      (final event, final emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (final cellData) {
            emit(
              state.copyWith(
                content: cellData?.content ?? "",
                url: cellData?.url ?? "",
              ),
            );
          },
          updateURL: (final String url) {
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
      onCellChanged: ((final cellData) {
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
  const factory URLCardCellEvent.updateURL(final String url) = _UpdateURL;
  const factory URLCardCellEvent.didReceiveCellUpdate(final URLCellDataPB? cell) =
      _DidReceiveCellUpdate;
}

@freezed
class URLCardCellState with _$URLCardCellState {
  const factory URLCardCellState({
    required final String content,
    required final String url,
  }) = _URLCardCellState;

  factory URLCardCellState.initial(final URLCellController context) {
    final cellData = context.getCellData();
    return URLCardCellState(
      content: cellData?.content ?? "",
      url: cellData?.url ?? "",
    );
  }
}
