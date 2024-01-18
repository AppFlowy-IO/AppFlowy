import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_service.dart';
import 'package:appflowy/plugins/database/application/field_settings/field_settings_service.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'row_detail_bloc.freezed.dart';

class RowDetailBloc extends Bloc<RowDetailEvent, RowDetailState> {
  final FieldController fieldController;
  final RowController rowController;

  RowDetailBloc({
    required this.fieldController,
    required this.rowController,
  }) : super(RowDetailState.initial()) {
    on<RowDetailEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
            final allCells = rowController.loadData().values.toList();
            int numHiddenFields = 0;
            final visibleCells = <CellContext>[];
            for (final cell in allCells) {
              final fieldInfo = fieldController.getField(cell.fieldId)!;
              final isVisible = fieldInfo.visibility!.isVisibleState();
              final isPrimary = fieldInfo.isPrimary;
              if (isVisible && !isPrimary) {
                visibleCells.add(cell);
              }
              if (!isVisible && !isPrimary) {
                numHiddenFields++;
              }
            }
            emit(
              RowDetailState(
                visibleCells: visibleCells,
                allCells: allCells,
                showHiddenFields: false,
                numHiddenFields: numHiddenFields,
              ),
            );
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
            await _toggleFieldVisibility(fieldId, emit);
          },
          reorderField: (fromIndex, toIndex) async {
            await _reorderField(fromIndex, toIndex, emit);
          },
          toggleHiddenFieldVisibility: () {
            final showHiddenFields = !state.showHiddenFields;
            final visibleCells = List<CellContext>.from(state.allCells);
            visibleCells.retainWhere((cellContext) {
              final fieldInfo = fieldController.getField(cellContext.fieldId);
              if (fieldInfo == null) {
                return false;
              }
              return !fieldInfo.isPrimary &&
                  (fieldInfo.visibility!.isVisibleState() || showHiddenFields);
            });
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

  void _startListening() {
    rowController.addListener(
      onRowChanged: (cellMap, reason) {
        if (isClosed) {
          return;
        }
        final allCellContext = cellMap.values.toList();
        int numHiddenFields = 0;
        final visibleCells = <CellContext>[];

        for (final cellContext in allCellContext) {
          final fieldInfo = fieldController.getField(cellContext.fieldId);
          if (fieldInfo == null) {
            continue;
          }
          final isHidden = fieldInfo.visibility == FieldVisibility.AlwaysHidden;
          final isPrimary = fieldInfo.isPrimary;

          if (!isHidden || state.showHiddenFields) {
            visibleCells.add(cellContext);
          }

          if (isHidden && !isPrimary) {
            numHiddenFields++;
          }
        }

        add(
          RowDetailEvent.didReceiveCellDatas(
            visibleCells,
            allCellContext,
            numHiddenFields,
          ),
        );
      },
    );
  }

  Future<void> _toggleFieldVisibility(
    String fieldId,
    Emitter<RowDetailState> emit,
  ) async {
    final fieldInfo = fieldController.getField(fieldId)!;
    final fieldVisibility = fieldInfo.visibility == FieldVisibility.AlwaysShown
        ? FieldVisibility.AlwaysHidden
        : FieldVisibility.AlwaysShown;
    final result =
        await FieldSettingsBackendService(viewId: rowController.viewId)
            .updateFieldSettings(
      fieldId: fieldId,
      fieldVisibility: fieldVisibility,
    );
    result.fold((l) {}, (err) => Log.error(err));
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

    final cells = List<CellContext>.from(state.visibleCells);
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
  /// Event to start listeners and load row data
  const factory RowDetailEvent.initial() = _Initial;

  /// Triggered by listeners to update row data
  const factory RowDetailEvent.didReceiveCellDatas(
    List<CellContext> visibleCells,
    List<CellContext> allCells,
    int numHiddenFields,
  ) = _DidReceiveCellDatas;

  /// Used to delete a field
  const factory RowDetailEvent.deleteField(String fieldId) = _DeleteField;

  /// Used to show/hide a field
  const factory RowDetailEvent.toggleFieldVisibility(String fieldId) =
      _ToggleFieldVisibility;

  /// Used to reorder a field
  const factory RowDetailEvent.reorderField(
    int fromIndex,
    int toIndex,
  ) = _ReorderField;

  /// Used to hide/show the hidden fields in the row detail page
  const factory RowDetailEvent.toggleHiddenFieldVisibility() =
      _ToggleHiddenFieldVisibility;
}

@freezed
class RowDetailState with _$RowDetailState {
  const factory RowDetailState({
    required List<CellContext> visibleCells,
    required List<CellContext> allCells,
    required bool showHiddenFields,
    required int numHiddenFields,
  }) = _RowDetailState;

  factory RowDetailState.initial() => const RowDetailState(
        visibleCells: [],
        allCells: [],
        showHiddenFields: false,
        numHiddenFields: 0,
      );
}
