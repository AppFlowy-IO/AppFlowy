import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_filter_bloc.freezed.dart';

class SelectOptionFilterEditorBloc
    extends Bloc<SelectOptionFilterEditorEvent, SelectOptionFilterEditorState> {
  SelectOptionFilterEditorBloc({
    required this.filterInfo,
    required this.delegate,
  })  : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(SelectOptionFilterEditorState.initial(filterInfo)) {
    _dispatch();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;
  final SelectOptionFilterDelegate delegate;

  void _dispatch() {
    on<SelectOptionFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
            _loadOptions();
          },
          updateCondition: (SelectOptionFilterConditionPB condition) {
            _filterBackendSvc.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              optionIds: state.filter.optionIds,
              fieldType: state.filterInfo.fieldInfo.fieldType,
            );
          },
          updateContent: (List<String> optionIds) {
            _filterBackendSvc.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: state.filter.condition,
              optionIds: optionIds,
              fieldType: state.filterInfo.fieldInfo.fieldType,
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
            final selectOptionFilter = filterInfo.selectOptionFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: selectOptionFilter,
              ),
            );
          },
          updateFilterDescription: (String desc) {
            emit(state.copyWith(filterDesc: desc));
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onUpdated: (filter) {
        if (!isClosed) {
          add(SelectOptionFilterEditorEvent.didReceiveFilter(filter));
        }
      },
    );
  }

  void _loadOptions() {
    if (!isClosed) {
      final options = delegate.loadOptions();
      String filterDesc = '';
      for (final option in options) {
        if (state.filter.optionIds.contains(option.id)) {
          filterDesc += "${option.name} ";
        }
      }
      add(SelectOptionFilterEditorEvent.updateFilterDescription(filterDesc));
    }
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class SelectOptionFilterEditorEvent with _$SelectOptionFilterEditorEvent {
  const factory SelectOptionFilterEditorEvent.initial() = _Initial;
  const factory SelectOptionFilterEditorEvent.didReceiveFilter(
    FilterPB filter,
  ) = _DidReceiveFilter;
  const factory SelectOptionFilterEditorEvent.updateCondition(
    SelectOptionFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory SelectOptionFilterEditorEvent.updateContent(
    List<String> optionIds,
  ) = _UpdateContent;
  const factory SelectOptionFilterEditorEvent.updateFilterDescription(
    String desc,
  ) = _UpdateDesc;
  const factory SelectOptionFilterEditorEvent.delete() = _Delete;
}

@freezed
class SelectOptionFilterEditorState with _$SelectOptionFilterEditorState {
  const factory SelectOptionFilterEditorState({
    required FilterInfo filterInfo,
    required SelectOptionFilterPB filter,
    required String filterDesc,
  }) = _GridFilterState;

  factory SelectOptionFilterEditorState.initial(FilterInfo filterInfo) {
    return SelectOptionFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.selectOptionFilter()!,
      filterDesc: '',
    );
  }
}
