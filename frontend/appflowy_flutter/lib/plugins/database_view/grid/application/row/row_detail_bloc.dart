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
            emit(
              state.copyWith(
                visibleCells: visibleCells,
                allCells: allCells,
                numHiddenFields: numHiddenFields,
              ),
            );
          },
          deleteField: (fieldId) async {
            final result = await FieldBackendService.deleteField(
              viewId: rowController.viewId,
              fieldId: fieldId,
            );
            result.fold((l) {}, (err) => Log.error(err));
          },
          toggleFieldVisibility: (fieldId) async {
            final fieldInfo = state.allCells
                .where((cellContext) => cellContext.fieldId == fieldId)
                .first
                .fieldInfo;
            final fieldVisibility =
                fieldInfo.visibility == FieldVisibility.AlwaysShown
                    ? FieldVisibility.AlwaysHidden
                    : FieldVisibility.AlwaysShown;
            final result =
                await FieldSettingsBackendService(viewId: rowController.viewId)
                    .updateFieldSettings(
              fieldId: fieldId,
              fieldVisibility: fieldVisibility,
            );
            result.fold(
              (l) {},
              (err) => Log.error(err),
            );
          },
          reorderField: (fromIndex, toIndex) async {
            await _reorderField(fromIndex, toIndex, emit);
          },
          toggleHiddenFieldVisibility: () {
            final showHiddenFields = !state.showHiddenFields;
            final visibleCells = List<DatabaseCellContext>.from(state.allCells);
            visibleCells.retainWhere(
              (cellContext) =>
                  !cellContext.fieldInfo.isPrimary &&
                  cellContext.isVisible(showHiddenFields: showHiddenFields),
            );
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
        int numHiddenFields = 0;
        final visibleCells = <DatabaseCellContext>[];
        for (final cell in allCells) {
          final isPrimary = cell.fieldInfo.isPrimary;

          if (cell.isVisible(showHiddenFields: state.showHiddenFields) &&
              !isPrimary) {
            visibleCells.add(cell);
          }

          if (!cell.isVisible() && !isPrimary) {
            numHiddenFields++;
          }
        }

        add(
          RowDetailEvent.didReceiveCellDatas(
            visibleCells,
            allCells,
            numHiddenFields,
          ),
        );
      },
    );
  }

  Future<void> _reorderField(
    int fromIndex,
    int toIndex,
    Emitter<RowDetailState> emit,
  ) async {
    if (fromIndex < toIndex) {
      toIndex--;
    }
    final fromId = state.visibleCells[fromIndex].fieldId;
    final toId = state.visibleCells[toIndex].fieldId;

    final cells = List<DatabaseCellContext>.from(state.visibleCells);
    cells.insert(toIndex, cells.removeAt(fromIndex));
    emit(state.copyWith(visibleCells: cells));

    final result = await FieldBackendService.moveField(
      viewId: rowController.viewId,
      fromFieldId: fromId,
      toFieldId: toId,
    );
    result.fold((l) {}, (err) => Log.error(err));
  }
}

@freezed
class RowDetailEvent with _$RowDetailEvent {
  const factory RowDetailEvent.initial() = _Initial;
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;
  const factory RowDetailEvent.toggleFieldVisibility(String fieldId) =
      _ToggleFieldVisibility;
  const factory RowDetailEvent.reorderField(
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
    int numHiddenFields = 0;
    final visibleCells = <DatabaseCellContext>[];
    for (final cell in allCells) {
      final isVisible = cell.isVisible();
      final isPrimary = cell.fieldInfo.isPrimary;

      if (isVisible && !isPrimary) {
        visibleCells.add(cell);
      }

      if (!isVisible && !isPrimary) {
        numHiddenFields++;
      }
    }

    return RowDetailState(
      visibleCells: visibleCells,
      allCells: allCells,
      showHiddenFields: false,
      numHiddenFields: numHiddenFields,
    );
  }
}
