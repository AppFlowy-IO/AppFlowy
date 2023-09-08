import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'timestamp_card_cell_bloc.freezed.dart';

class TimestampCardCellBloc
    extends Bloc<TimestampCardCellEvent, TimestampCardCellState> {
  final TimestampCellController cellController;
  void Function()? _onCellChangedFn;

  TimestampCardCellBloc({required this.cellController})
      : super(TimestampCardCellState.initial(cellController)) {
    on<TimestampCardCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (TimestampCellDataPB? cellData) {
            emit(
              state.copyWith(
                data: cellData,
                dateStr: cellData?.dateTime ?? "",
              ),
            );
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
      onCellChanged: ((data) {
        if (!isClosed) {
          add(TimestampCardCellEvent.didReceiveCellUpdate(data));
        }
      }),
    );
  }
}

@freezed
class TimestampCardCellEvent with _$TimestampCardCellEvent {
  const factory TimestampCardCellEvent.initial() = _InitialCell;
  const factory TimestampCardCellEvent.didReceiveCellUpdate(
    TimestampCellDataPB? data,
  ) = _DidReceiveCellUpdate;
}

@freezed
class TimestampCardCellState with _$TimestampCardCellState {
  const factory TimestampCardCellState({
    required TimestampCellDataPB? data,
    required String dateStr,
    required FieldInfo fieldInfo,
  }) = _TimestampCardCellState;

  factory TimestampCardCellState.initial(TimestampCellController context) {
    final cellData = context.getCellData();

    return TimestampCardCellState(
      fieldInfo: context.fieldInfo,
      data: cellData,
      dateStr: cellData?.dateTime ?? "",
    );
  }
}
