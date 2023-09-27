import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final RowController rowController;

  RowDetailBloc({
    required this.rowController,
  }) : super(RowDetailState.initial(rowController.loadData())) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          didReceiveCellDatas: (visibleCells, allCells, numHiddenFields) {
            // Log.debug(
            //   "didReceiveCellDatas ${allCells.length} $numHiddenFields",
            // );
            emit(
              state.copyWith(
                visibleCells: visibleCells,
                allCells: allCells,
                numHiddenFields: numHiddenFields,
              ),
            );
          },
          deleteField: (fieldId) {
            final fieldService = FieldBackendService(
              viewId: rowController.viewId,
              fieldId: fieldId,
            );
            fieldService.deleteField();
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
          reorderField:
              (reorderedFieldId, targetFieldId, fromIndex, toIndex) async {
            await _reorderField(
              reorderedFieldId,
              targetFieldId,
              fromIndex,
              toIndex,
              emit,
            );
          },
          toggleHiddenFieldVisibility: () {
            final showHiddenFields = !state.showHiddenFields;
            final visibleCells = List<DatabaseCellContext>.from(state.allCells);
            visibleCells
                .removeWhere((cellContext) => cellContext.fieldInfo.isPrimary);
            if (!showHiddenFields) {
              visibleCells
                  .removeWhere((cellContext) => !cellContext.isVisible());
            }
            emit(
              state.copyWith(
                showHiddenFields: showHiddenFields,
                visibleCells: visibleCells,
              ),
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
      onRowChanged: (cellMap, reason) {
        if (isClosed) {
          return;
        }
        final allCells = cellMap.values.toList();
        final visibleCells = allCells
            .where(
              (cellContext) =>
                  cellContext.isVisible(
                    showHiddenFields: state.showHiddenFields,
                  ) &&
                  !cellContext.fieldInfo.isPrimary,
            )
            .toList();
        // Log.debug(
        //   "onRowsChanged. Length of cellMap: ${allCells.length}, length of visibleCells: ${visibleCells.length}, showHiddenFields: ${state.showHiddenFields}",
        // );
        // print("$visibleCells");
        add(
          RowDetailEvent.didReceiveCellDatas(
            visibleCells,
            allCells,
            allCells.length - visibleCells.length - 1,
          ),
        );
      },
    );
  }

  Future<void> _reorderField(
    String reorderedFieldId,
    String targetFieldId,
    int fromIndex,
    int toIndex,
    Emitter<RowDetailState> emit,
  ) async {
    final cells = List<DatabaseCellContext>.from(state.visibleCells);
    cells.insert(toIndex, cells.removeAt(fromIndex));
    emit(state.copyWith(visibleCells: cells));

    final fromIndexInAllFields =
        state.allCells.indexWhere((cell) => cell.fieldId == reorderedFieldId);
    final toIndexInAllFields =
        state.allCells.indexWhere((cell) => cell.fieldId == targetFieldId);

    final fieldService = FieldBackendService(
      viewId: rowController.viewId,
      fieldId: reorderedFieldId,
    );
    final result = await fieldService.moveField(
      fromIndexInAllFields,
      toIndexInAllFields,
    );
    result.fold((l) {}, (err) => Log.error(err));
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;
  const factory RowDetailEvent.showField(String fieldId) = _ShowField;
  const factory RowDetailEvent.hideField(String fieldId) = _HideField;
  const factory RowDetailEvent.reorderField(
    String reorderFieldID,
    String targetFieldID,
    int fromIndex,
    int toIndex,
  ) = _ReorderField;
  const factory RowDetailEvent.toggleHiddenFieldVisibility() =
      _ToggleHiddenFieldVisibility;
  const factory RowDetailEvent.didReceiveCellDatas(
    List<DatabaseCellContext> visibleCells,
    List<DatabaseCellContext> allCells,
    int numHiddenFields,
  ) = _DidReceiveCellDatas;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required List<DatabaseCellContext> visibleCells,
    required List<DatabaseCellContext> allCells,
    required bool showHiddenFields,
    required int numHiddenFields,
  }) = _RowDetailState;

  factory RowDetailState.initial(CellContextByFieldId cellByFieldId) {
    final allCells = cellByFieldId.values.toList();
    final visibleCells = allCells
        .where(
          (cellContext) =>
              cellContext.isVisible() && !cellContext.fieldInfo.isPrimary,
        )
        .toList();

    return RowDetailState(
      visibleCells: visibleCells,
      allCells: allCells,
      showHiddenFields: false,
      numHiddenFields: allCells.length - visibleCells.length - 1,
    );
  }
}
