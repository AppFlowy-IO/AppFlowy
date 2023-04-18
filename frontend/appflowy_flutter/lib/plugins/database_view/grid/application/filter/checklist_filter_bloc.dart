import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'checklist_filter_bloc.freezed.dart';

class ChecklistFilterEditorBloc
    extends Bloc<ChecklistFilterEditorEvent, ChecklistFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  ChecklistFilterEditorBloc({
    required this.filterInfo,
  })  : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(ChecklistFilterEditorState.initial(filterInfo)) {
    on<ChecklistFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (ChecklistFilterConditionPB condition) {
            _filterBackendSvc.insertChecklistFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
            );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
              fieldType: filterInfo.fieldInfo.fieldType,
            );
          },
          didReceiveFilter: (FilterPB filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checklistFilter = filterInfo.checklistFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: checklistFilter,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const ChecklistFilterEditorEvent.delete());
      },
      onUpdated: (filter) {
        if (!isClosed) {
          add(ChecklistFilterEditorEvent.didReceiveFilter(filter));
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class ChecklistFilterEditorEvent with _$ChecklistFilterEditorEvent {
  const factory ChecklistFilterEditorEvent.initial() = _Initial;
  const factory ChecklistFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory ChecklistFilterEditorEvent.updateCondition(
    ChecklistFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory ChecklistFilterEditorEvent.delete() = _Delete;
}

@freezed
class ChecklistFilterEditorState with _$ChecklistFilterEditorState {
  const factory ChecklistFilterEditorState({
    required FilterInfo filterInfo,
    required ChecklistFilterPB filter,
    required String filterDesc,
  }) = _GridFilterState;

  factory ChecklistFilterEditorState.initial(FilterInfo filterInfo) {
    return ChecklistFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.checklistFilter()!,
      filterDesc: '',
    );
  }
}
