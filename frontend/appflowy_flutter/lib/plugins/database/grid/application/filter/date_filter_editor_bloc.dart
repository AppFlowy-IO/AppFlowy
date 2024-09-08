import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_filter_editor_bloc.freezed.dart';

class DateFilterEditorBloc
    extends Bloc<DateFilterEditorEvent, DateFilterEditorState> {
  DateFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(DateFilterEditorState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<DateFilterEditorEvent>(
      (event, emit) async {
        event.when(
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: filterInfo.dateFilter()!,
              ),
            );
          },
          updateCondition: (DateFilterConditionPB condition) {
            _filterBackendSvc.insertDateFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              start: state.filter.start.toInt(),
              end: state.filter.end.toInt(),
              timestamp: state.filter.timestamp.toInt(),
            );
          },
          updateTimestamp: (timestamp) {
            _filterBackendSvc.insertDateFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: state.filter.condition,
              timestamp: timestamp,
            );
          },
          updateRange: (start, end) {
            assert(start != null || end != null);
            _filterBackendSvc.insertDateFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: state.filter.condition,
              start: start ?? state.filter.start.toInt(),
              end: end ?? state.filter.end.toInt(),
            );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onUpdated: (filter) {
        if (!isClosed) {
          add(DateFilterEditorEvent.didReceiveFilter(filter));
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
class DateFilterEditorEvent with _$DateFilterEditorEvent {
  const factory DateFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory DateFilterEditorEvent.updateCondition(
    DateFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory DateFilterEditorEvent.updateTimestamp(
    int timestamp,
  ) = _UpdateTimestamp;
  const factory DateFilterEditorEvent.updateRange({
    int? start,
    int? end,
  }) = _UpdateRange;
  const factory DateFilterEditorEvent.delete() = _Delete;
}

@freezed
class DateFilterEditorState with _$DateFilterEditorState {
  const factory DateFilterEditorState({
    required FilterInfo filterInfo,
    required DateFilterPB filter,
  }) = _DateFilterEditorState;

  factory DateFilterEditorState.initial(FilterInfo filterInfo) {
    return DateFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.dateFilter()!,
    );
  }
}
