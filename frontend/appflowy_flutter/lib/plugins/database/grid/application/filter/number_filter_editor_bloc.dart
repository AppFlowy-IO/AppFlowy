import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_filter_editor_bloc.freezed.dart';

class NumberFilterBloc extends Bloc<NumberFilterEvent, NumberFilterState> {
  NumberFilterBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(NumberFilterState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<NumberFilterEvent>(
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
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onUpdated: (filter) {
        if (!isClosed) {
          add(NumberFilterEvent.didReceiveFilter(filter));
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
class NumberFilterEvent with _$NumberFilterEvent {
  const factory NumberFilterEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory NumberFilterEvent.updateCondition(
    NumberFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory NumberFilterEvent.updateContent(String content) =
      _UpdateContent;
}

@freezed
class NumberFilterState with _$NumberFilterState {
  const factory NumberFilterState({
    required FilterInfo filterInfo,
    required NumberFilterPB filter,
  }) = _NumberFilterEditorState;

  factory NumberFilterState.initial(FilterInfo filterInfo) {
    return NumberFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.numberFilter()!,
    );
  }
}
