import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../../application/cell/cell_service.dart';
import '../../../application/field/field_service.dart';
import '../../../application/row/row_data_controller.dart';
part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final RowController dataController;

  RowDetailBloc({
    required this.dataController,
  }) : super(RowDetailState.initial()) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            await _startListening();
            final cells = dataController.loadData();
            if (!isClosed) {
              add(RowDetailEvent.didReceiveCellDatas(cells.values.toList()));
            }
          },
          didReceiveCellDatas: (_DidReceiveCellDatas value) {
            emit(state.copyWith(gridCells: value.gridCells));
          },
          deleteField: (_DeleteField value) {
            final fieldService = FieldBackendService(
              viewId: dataController.viewId,
              fieldId: value.fieldId,
            );
            fieldService.deleteField();
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    dataController.dispose();
    return super.close();
  }

  Future<void> _startListening() async {
    dataController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(RowDetailEvent.didReceiveCellDatas(cells.values.toList()));
        }
      },
    );
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;
  const factory RowDetailEvent.didReceiveCellDatas(
      List<CellIdentifier> gridCells) = _DidReceiveCellDatas;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required List<CellIdentifier> gridCells,
  }) = _RowDetailState;

  factory RowDetailState.initial() => RowDetailState(
        gridCells: List.empty(),
      );
}
