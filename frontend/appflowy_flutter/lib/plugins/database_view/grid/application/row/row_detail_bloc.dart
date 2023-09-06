import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../../application/cell/cell_service.dart';
import '../../../application/field/field_service.dart';
import '../../../application/row/row_controller.dart';
part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final RowBackendService rowService;
  final RowController rowController;

  RowDetailBloc({
    required this.rowController,
  })  : rowService = RowBackendService(viewId: rowController.viewId),
        super(RowDetailState.initial()) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
            final cells = rowController.loadData();
            if (!isClosed) {
              add(RowDetailEvent.didReceiveCellDatas(cells.values.toList()));
            }
          },
          didReceiveCellDatas: (cells) {
            emit(state.copyWith(cells: cells));
          },
          deleteField: (fieldId) {
            _fieldBackendService(fieldId).deleteField();
          },
          showField: (fieldId) async {
            final result =
                await FieldSettingsBackendService(viewId: rowController.viewId)
                    .updateFieldSettings(
              fieldId: fieldId,
              fieldVisibility: FieldVisibility.AlwaysShown,
            );
            result.fold(
              (l) {},
              (err) => Log.error(err),
            );
          },
          hideField: (fieldId) async {
            final result =
                await FieldSettingsBackendService(viewId: rowController.viewId)
                    .updateFieldSettings(
              fieldId: fieldId,
              fieldVisibility: FieldVisibility.AlwaysHidden,
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
    rowController.dispose();
    return super.close();
  }

  Future<void> _startListening() async {
    rowController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(RowDetailEvent.didReceiveCellDatas(cells.values.toList()));
        }
      },
    );
  }

  FieldBackendService _fieldBackendService(String fieldId) {
    return FieldBackendService(
      viewId: rowController.viewId,
      fieldId: fieldId,
    );
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;
  const factory RowDetailEvent.showField(String fieldId) = _ShowField;
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
    required List<DatabaseCellContext> cells,
  }) = _RowDetailState;

  factory RowDetailState.initial() => RowDetailState(
        cells: List.empty(),
      );
}
