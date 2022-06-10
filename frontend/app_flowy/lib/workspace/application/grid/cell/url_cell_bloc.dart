import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'url_cell_bloc.freezed.dart';

class URLCellBloc extends Bloc<URLCellEvent, URLCellState> {
  final GridURLCellContext cellContext;
  void Function()? _onCellChangedFn;
  URLCellBloc({
    required this.cellContext,
  }) : super(URLCellState.initial(cellContext)) {
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
            cellContext.saveCellData(url, deduplicate: true);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
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
  const factory URLCellEvent.didReceiveCellUpdate(URLCellData? cell) = _DidReceiveCellUpdate;
}

@freezed
class URLCellState with _$URLCellState {
  const factory URLCellState({
    required String content,
    required String url,
  }) = _URLCellState;

  factory URLCellState.initial(GridURLCellContext context) {
    final cellData = context.getCellData();
    return URLCellState(
      content: cellData?.content ?? "",
      url: cellData?.url ?? "",
    );
  }
}
