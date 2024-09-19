import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_filter_bloc.freezed.dart';

class SelectOptionFilterBloc
    extends Bloc<SelectOptionFilterEvent, SelectOptionFilterState> {
  SelectOptionFilterBloc({
    required this.fieldController,
    required FilterInfo filterInfo,
    required this.delegate,
  })  : filterId = filterInfo.filterId,
        fieldId = filterInfo.fieldId,
        _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(
          SelectOptionFilterState.initial(
            filterInfo,
            delegate.getOptions(filterInfo.fieldInfo),
          ),
        ) {
    _dispatch();
    _startListening();
  }

  final FieldController fieldController;
  final String filterId;
  final String fieldId;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;
  final SelectOptionFilterDelegate delegate;

  void Function(FieldInfo)? _onFieldChanged;

  void _dispatch() {
    on<SelectOptionFilterEvent>(
      (event, emit) async {
        event.when(
          updateCondition: (SelectOptionFilterConditionPB condition) {
            _filterBackendSvc.insertSelectOptionFilter(
              filterId: filterId,
              fieldId: fieldId,
              condition: condition,
              optionIds: state.filter.optionIds,
              fieldType: state.filterInfo.fieldInfo.fieldType,
            );
          },
          updateContent: (List<String> optionIds) {
            _filterBackendSvc.insertSelectOptionFilter(
              filterId: filterId,
              fieldId: fieldId,
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
          didReceiveField: (field) {
            final filterInfo = state.filterInfo.copyWith(fieldInfo: field);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                options: delegate.getOptions(field),
              ),
            );
          },
          selectOption: (option) {
            final selectedOptionIds = delegate.selectOption(
              state.filter.optionIds,
              option.id,
              state.filter.condition,
            );

            _updateSelectOptions(selectedOptionIds);
          },
          unSelectOption: (option) {
            final selectedOptionIds = Set<String>.from(state.filter.optionIds)
              ..remove(option.id);

            _updateSelectOptions(selectedOptionIds);
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
    _onFieldChanged = (field) {
      if (!isClosed) {
        add(SelectOptionFilterEvent.didReceiveField(field));
      }
    };
    fieldController.addSingleFieldListener(
      fieldId,
      onFieldChanged: _onFieldChanged!,
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    if (_onFieldChanged != null) {
      fieldController.removeSingleFieldListener(
        fieldId: fieldId,
        onFieldChanged: _onFieldChanged!,
      );
    }
    return super.close();
  }

  void _updateSelectOptions(
    Set<String> selectedOptionIds,
  ) {
    final optionIds = state.options
        .map((e) => e.id)
        .where(selectedOptionIds.contains)
        .toList();
    _filterBackendSvc.insertSelectOptionFilter(
      filterId: filterId,
      fieldId: fieldId,
      condition: state.filter.condition,
      optionIds: optionIds,
      fieldType: state.filterInfo.fieldInfo.fieldType,
    );
  }
}

@freezed
class SelectOptionFilterEvent with _$SelectOptionFilterEvent {
  const factory SelectOptionFilterEvent.didReceiveFilter(
    FilterPB filter,
  ) = _DidReceiveFilter;
  const factory SelectOptionFilterEvent.didReceiveField(
    FieldInfo field,
  ) = _DidReceiveField;
  const factory SelectOptionFilterEvent.updateCondition(
    SelectOptionFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory SelectOptionFilterEvent.updateContent(
    List<String> optionIds,
  ) = _UpdateContent;
  const factory SelectOptionFilterEvent.selectOption(
    SelectOptionPB option,
  ) = _SelectOption;
  const factory SelectOptionFilterEvent.unSelectOption(
    SelectOptionPB option,
  ) = _UnSelectOption;
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
