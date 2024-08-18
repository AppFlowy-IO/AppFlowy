import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_editor_bloc.freezed.dart';

class CalendarEventEditorBloc
    extends Bloc<CalendarEventEditorEvent, CalendarEventEditorState> {
  CalendarEventEditorBloc({
    required this.fieldController,
    required this.rowController,
    required this.layoutSettings,
  }) : super(CalendarEventEditorState.initial()) {
    _dispatch();
  }

  final FieldController fieldController;
  final RowController rowController;
  final CalendarLayoutSettingPB layoutSettings;

  void _dispatch() {
    on<CalendarEventEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
            final primaryFieldId = fieldController.fieldInfos
                .firstWhere((fieldInfo) => fieldInfo.isPrimary)
                .id;
            final cells = rowController
                .loadCells()
                .where(
                  (cellContext) =>
                      _filterCellContext(cellContext, primaryFieldId),
                )
                .toList();
            add(CalendarEventEditorEvent.didReceiveCellDatas(cells));
          },
          didReceiveCellDatas: (cells) {
            emit(state.copyWith(cells: cells));
          },
          delete: () async {
            final result = await RowBackendService.deleteRows(
              rowController.viewId,
              [rowController.rowId],
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
        );
      },
    );
  }

  void _startListening() {
    rowController.addListener(
      onRowChanged: (cells, reason) {
        if (isClosed) {
          return;
        }
        final primaryFieldId = fieldController.fieldInfos
            .firstWhere((fieldInfo) => fieldInfo.isPrimary)
            .id;
        final cellData = cells
            .where(
              (cellContext) => _filterCellContext(cellContext, primaryFieldId),
            )
            .toList();
        add(CalendarEventEditorEvent.didReceiveCellDatas(cellData));
      },
    );
  }

  bool _filterCellContext(CellContext cellContext, String primaryFieldId) {
    return fieldController
            .getField(cellContext.fieldId)!
            .fieldSettings!
            .visibility
            .isVisibleState() ||
        cellContext.fieldId == layoutSettings.fieldId ||
        cellContext.fieldId == primaryFieldId;
  }

  @override
  Future<void> close() async {
    await rowController.dispose();
    return super.close();
  }
}

@freezed
class CalendarEventEditorEvent with _$CalendarEventEditorEvent {
  const factory CalendarEventEditorEvent.initial() = _Initial;
  const factory CalendarEventEditorEvent.didReceiveCellDatas(
    List<CellContext> cells,
  ) = _DidReceiveCellDatas;
  const factory CalendarEventEditorEvent.delete() = _Delete;
}

@freezed
class CalendarEventEditorState with _$CalendarEventEditorState {
  const factory CalendarEventEditorState({
    required List<CellContext> cells,
  }) = _CalendarEventEditorState;

  factory CalendarEventEditorState.initial() =>
      const CalendarEventEditorState(cells: []);
}
