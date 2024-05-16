import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_filter_editor_bloc.freezed.dart';

class TimerFilterEditorBloc
    extends Bloc<TimerFilterEditorEvent, TimerFilterEditorState> {
  TimerFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TimerFilterEditorState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<TimerFilterEditorEvent>(
      (event, emit) async {
        event.when(
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: filterInfo.timerFilter()!,
              ),
            );
          },
          updateCondition: (NumberFilterConditionPB condition) {
            _filterBackendSvc.insertTimerFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              content: state.filter.content,
            );
          },
          updateContent: (content) {
            _filterBackendSvc.insertTimerFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: state.filter.condition,
              content: content,
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
          add(TimerFilterEditorEvent.didReceiveFilter(filter));
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
class TimerFilterEditorEvent with _$TimerFilterEditorEvent {
  const factory TimerFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory TimerFilterEditorEvent.updateCondition(
    NumberFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory TimerFilterEditorEvent.updateContent(String content) =
      _UpdateContent;
  const factory TimerFilterEditorEvent.delete() = _Delete;
}

@freezed
class TimerFilterEditorState with _$TimerFilterEditorState {
  const factory TimerFilterEditorState({
    required FilterInfo filterInfo,
    required TimerFilterPB filter,
  }) = _TimerFilterEditorState;

  factory TimerFilterEditorState.initial(FilterInfo filterInfo) {
    return TimerFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.timerFilter()!,
    );
  }
}
