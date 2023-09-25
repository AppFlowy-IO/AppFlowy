import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_editor_bloc.freezed.dart';

class CalendarEventEditorBloc
    extends Bloc<CalendarEventEditorEvent, CalendarEventEditorState> {
  final RowController rowController;
  final CalendarLayoutSettingPB layoutSettings;
  final RowBackendService _rowService;

  CalendarEventEditorBloc({
    required this.rowController,
    required this.layoutSettings,
  })  : _rowService = RowBackendService(viewId: rowController.viewId),
        super(CalendarEventEditorState.initial()) {
    on<CalendarEventEditorEvent>((event, emit) async {
      await event.when(
        initial: () {
          _startListening();
          final cells = rowController.loadData();
          if (!isClosed) {
            add(
              CalendarEventEditorEvent.didReceiveCellDatas(
                cells.values.toList(),
              ),
            );
          }
        },
        didReceiveCellDatas: (cells) {
          emit(state.copyWith(cells: cells));
        },
        delete: () async {
          final result = await _rowService.deleteRow(rowController.rowId);
          result.fold((l) => null, (err) => Log.error(err));
        },
      );
    });
  }

  void _startListening() {
    rowController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(
            CalendarEventEditorEvent.didReceiveCellDatas(cells.values.toList()),
          );
        }
      },
    );
  }

  @override
  Future<void> close() async {
    rowController.dispose();
    return super.close();
  }
}

@freezed
class CalendarEventEditorEvent with _$CalendarEventEditorEvent {
  const factory CalendarEventEditorEvent.initial() = _Initial;
  const factory CalendarEventEditorEvent.didReceiveCellDatas(
    List<DatabaseCellContext> cells,
  ) = _DidReceiveCellDatas;
  const factory CalendarEventEditorEvent.delete() = _Delete;
}

@freezed
class CalendarEventEditorState with _$CalendarEventEditorState {
  const factory CalendarEventEditorState({
    required List<DatabaseCellContext> cells,
  }) = _CalendarEventEditorState;

  factory CalendarEventEditorState.initial() =>
      CalendarEventEditorState(cells: List.empty());
}
