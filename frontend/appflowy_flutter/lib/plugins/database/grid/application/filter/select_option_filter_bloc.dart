import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_filter_bloc.freezed.dart';

class SelectOptionFilterBloc
    extends Bloc<SelectOptionFilterEvent, SelectOptionFilterState> {
  SelectOptionFilterBloc({
    required this.filterInfo,
    required this.delegate,
  })  : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(
          SelectOptionFilterState.initial(
            filterInfo,
            delegate.loadOptions(),
          ),
        ) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;
  final SelectOptionFilterDelegate delegate;

  void _dispatch() {
    on<SelectOptionFilterEvent>(
      (event, emit) async {
        event.when(
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
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onUpdated: (filter) {
        if (!isClosed) {
          add(SelectOptionFilterEvent.didReceiveFilter(filter));
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
class SelectOptionFilterEvent with _$SelectOptionFilterEvent {
  const factory SelectOptionFilterEvent.didReceiveFilter(
    FilterPB filter,
  ) = _DidReceiveFilter;
  const factory SelectOptionFilterEvent.updateCondition(
    SelectOptionFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory SelectOptionFilterEvent.updateContent(
    List<String> optionIds,
  ) = _UpdateContent;
}

@freezed
class SelectOptionFilterState with _$SelectOptionFilterState {
  const factory SelectOptionFilterState({
    required FilterInfo filterInfo,
    required SelectOptionFilterPB filter,
    required List<SelectOptionPB> options,
  }) = _SelectOptionFilterState;

  factory SelectOptionFilterState.initial(
    FilterInfo filterInfo,
    List<SelectOptionPB> options,
  ) {
    return SelectOptionFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.selectOptionFilter()!,
      options: options,
    );
  }
}
