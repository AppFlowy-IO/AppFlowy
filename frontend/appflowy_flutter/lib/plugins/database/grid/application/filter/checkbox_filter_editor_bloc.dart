import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkbox_filter_editor_bloc.freezed.dart';

class CheckboxFilterEditorBloc
    extends Bloc<CheckboxFilterEditorEvent, CheckboxFilterEditorState> {
  CheckboxFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(CheckboxFilterEditorState.initial(filterInfo)) {
    _dispatch();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<CheckboxFilterEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (CheckboxFilterConditionPB condition) {
            _filterBackendSvc.insertCheckboxFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
            );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
            );
          },
          didReceiveFilter: (FilterPB filter) {
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
          add(CheckboxFilterEditorEvent.didReceiveFilter(filter));
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
class CheckboxFilterEditorEvent with _$CheckboxFilterEditorEvent {
  const factory CheckboxFilterEditorEvent.initial() = _Initial;
  const factory CheckboxFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory CheckboxFilterEditorEvent.updateCondition(
    CheckboxFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory CheckboxFilterEditorEvent.delete() = _Delete;
}

@freezed
class CheckboxFilterEditorState with _$CheckboxFilterEditorState {
  const factory CheckboxFilterEditorState({
    required FilterInfo filterInfo,
    required CheckboxFilterPB filter,
  }) = _GridFilterState;

  factory CheckboxFilterEditorState.initial(FilterInfo filterInfo) {
    return CheckboxFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.checkboxFilter()!,
    );
  }
}
