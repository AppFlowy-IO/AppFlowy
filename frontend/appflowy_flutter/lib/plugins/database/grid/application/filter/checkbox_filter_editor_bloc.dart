import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkbox_filter_editor_bloc.freezed.dart';

class CheckboxFilterBloc
    extends Bloc<CheckboxFilterEvent, CheckboxFilterState> {
  CheckboxFilterBloc({
    required FilterInfo filterInfo,
  })  : filterId = filterInfo.filterId,
        fieldId = filterInfo.fieldId,
        _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filterId,
        ),
        super(CheckboxFilterState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final String filterId;
  final String fieldId;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<CheckboxFilterEvent>(
      (event, emit) async {
        await event.when(
          updateCondition: (condition) {
            return _filterBackendSvc.insertCheckboxFilter(
              filterId: filterId,
              fieldId: fieldId,
              condition: condition,
            );
          },
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checkboxFilter = filterInfo.checkboxFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: checkboxFilter,
              ),
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
          add(CheckboxFilterEvent.didReceiveFilter(filter));
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
class CheckboxFilterEvent with _$CheckboxFilterEvent {
  const factory CheckboxFilterEvent.didReceiveFilter(
    FilterPB filter,
  ) = _DidReceiveFilter;
  const factory CheckboxFilterEvent.updateCondition(
    CheckboxFilterConditionPB condition,
  ) = _UpdateCondition;
}

@freezed
class CheckboxFilterState with _$CheckboxFilterState {
  const factory CheckboxFilterState({
    required FilterInfo filterInfo,
    required CheckboxFilterPB filter,
  }) = _CheckboxFilterState;

  factory CheckboxFilterState.initial(FilterInfo filterInfo) {
    return CheckboxFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.checkboxFilter()!,
    );
  }
}
