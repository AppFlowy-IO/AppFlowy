import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../../application/cell/cell_service.dart';
import '../../../application/field/field_service.dart';
import '../../../application/row/row_data_controller.dart';
part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final RowBackendService rowService;
  final RowController dataController;

  RowDetailBloc({
    required this.dataController,
  })  : rowService = RowBackendService(viewId: dataController.viewId),
        super(RowDetailState.initial()) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
            final cells = dataController.loadData();
            if (!isClosed) {
              add(RowDetailEvent.didReceiveCellDatas(cells.values.toList()));
            }
          },
          didReceiveCellDatas: (cells) {
            emit(state.copyWith(gridCells: cells));
          },
          deleteField: (fieldId) {
            _fieldBackendService(fieldId).deleteField();
          },
          hideField: (fieldId) async {
            final result = await _fieldBackendService(fieldId).updateField(
              visibility: false,
            );
            result.fold(
              (l) {},
              (err) => Log.error(err),
            );
          },
          deleteRow: (rowId) async {
            await rowService.deleteRow(rowId);
          },
          duplicateRow: (String rowId, String? groupId) async {
            await rowService.duplicateRow(
              rowId: rowId,
              groupId: groupId,
            );
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

  FieldBackendService _fieldBackendService(String fieldId) {
    return FieldBackendService(
      viewId: dataController.viewId,
      fieldId: fieldId,
    );
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;
  const factory RowDetailEvent.hideField(String fieldId) = _HideField;
  const factory RowDetailEvent.deleteRow(String rowId) = _DeleteRow;
  const factory RowDetailEvent.duplicateRow(String rowId, String? groupId) =
      _DuplicateRow;
  const factory RowDetailEvent.didReceiveCellDatas(
    List<DatabaseCellContext> gridCells,
  ) = _DidReceiveCellDatas;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required List<DatabaseCellContext> gridCells,
  }) = _RowDetailState;

  factory RowDetailState.initial() => RowDetailState(
        gridCells: List.empty(),
      );
}
