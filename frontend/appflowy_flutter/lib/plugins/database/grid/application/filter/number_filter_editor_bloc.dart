import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_filter_editor_bloc.freezed.dart';

class NumberFilterEditorBloc
    extends Bloc<NumberFilterEditorEvent, NumberFilterEditorState> {
  NumberFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(NumberFilterEditorState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<NumberFilterEditorEvent>(
      (event, emit) async {
        event.when(
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: filterInfo.numberFilter()!,
              ),
            );
          },
          updateCondition: (NumberFilterConditionPB condition) {
            _filterBackendSvc.insertNumberFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              content: state.filter.content,
            );
          },
          updateContent: (content) {
            _filterBackendSvc.insertNumberFilter(
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
          add(NumberFilterEditorEvent.didReceiveFilter(filter));
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
class NumberFilterEditorEvent with _$NumberFilterEditorEvent {
  const factory NumberFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory NumberFilterEditorEvent.updateCondition(
    NumberFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory NumberFilterEditorEvent.updateContent(String content) =
      _UpdateContent;
  const factory NumberFilterEditorEvent.delete() = _Delete;
}

@freezed
class NumberFilterEditorState with _$NumberFilterEditorState {
  const factory NumberFilterEditorState({
    required FilterInfo filterInfo,
    required NumberFilterPB filter,
  }) = _NumberFilterEditorState;

  factory NumberFilterEditorState.initial(FilterInfo filterInfo) {
    return NumberFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.numberFilter()!,
    );
  }
}
