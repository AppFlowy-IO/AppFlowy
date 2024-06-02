import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_filter_editor_bloc.freezed.dart';

class TimeFilterEditorBloc
    extends Bloc<TimeFilterEditorEvent, TimeFilterEditorState> {
  TimeFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TimeFilterEditorState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<TimeFilterEditorEvent>(
      (event, emit) async {
        event.when(
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: filterInfo.timeFilter()!,
              ),
            );
          },
          updateCondition: (NumberFilterConditionPB condition) {
            _filterBackendSvc.insertTimeFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              content: state.filter.content,
            );
          },
          updateContent: (content) {
            _filterBackendSvc.insertTimeFilter(
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
          add(TimeFilterEditorEvent.didReceiveFilter(filter));
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
class TimeFilterEditorEvent with _$TimeFilterEditorEvent {
  const factory TimeFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory TimeFilterEditorEvent.updateCondition(
    NumberFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory TimeFilterEditorEvent.updateContent(String content) =
      _UpdateContent;
  const factory TimeFilterEditorEvent.delete() = _Delete;
}

@freezed
class TimeFilterEditorState with _$TimeFilterEditorState {
  const factory TimeFilterEditorState({
    required FilterInfo filterInfo,
    required TimeFilterPB filter,
  }) = _TimeFilterEditorState;

  factory TimeFilterEditorState.initial(FilterInfo filterInfo) {
    return TimeFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.timeFilter()!,
    );
  }
}
