import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_service.dart';

part 'filter_edit_bloc.freezed.dart';

class GridFilterEditBloc
    extends Bloc<GridFilterEditEvent, GridFilterEditState> {
  final String viewId;
  final FilterFFIService _ffiService;
  final GridFieldController fieldController;
  void Function(List<FilterPB>)? _onFilterFn;
  GridFilterEditBloc({required this.viewId, required this.fieldController})
      : _ffiService = FilterFFIService(viewId: viewId),
        super(GridFilterEditState.initial()) {
    on<GridFilterEditEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          deleteFilter: (
            String fieldId,
            String filterId,
            FieldType fieldType,
          ) {
            _ffiService.deleteFilter(
              fieldId: fieldId,
              filterId: filterId,
              fieldType: fieldType,
            );
          },
          didReceiveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          createCheckboxFilter: (
            String fieldId,
            CheckboxFilterCondition condition,
          ) {
            _ffiService.createCheckboxFilter(
              fieldId: fieldId,
              condition: condition,
            );
          },
          createNumberFilter: (
            String fieldId,
            NumberFilterCondition condition,
            String content,
          ) {
            _ffiService.createNumberFilter(
              fieldId: fieldId,
              condition: condition,
              content: content,
            );
          },
          createTextFilter: (
            String fieldId,
            TextFilterCondition condition,
            String content,
          ) {
            _ffiService.createTextFilter(
              fieldId: fieldId,
              condition: condition,
            );
          },
          createDateFilter: (
            String fieldId,
            DateFilterCondition condition,
            int timestamp,
          ) {
            _ffiService.createDateFilter(
              fieldId: fieldId,
              condition: condition,
              timestamp: timestamp,
            );
          },
          createDateFilterInRange: (
            String fieldId,
            DateFilterCondition condition,
            int start,
            int end,
          ) {
            _ffiService.createDateFilter(
              fieldId: fieldId,
              condition: condition,
              start: start,
              end: end,
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(GridFilterEditEvent.didReceiveFilters(filters));
    };
    fieldController.addListener(onFilters: _onFilterFn);
  }

  @override
  Future<void> close() async {
    if (_onFilterFn != null) {
      fieldController.removeListener(onFiltersListener: _onFilterFn);
      _onFilterFn = null;
    }
    return super.close();
  }
}

@freezed
class GridFilterEditEvent with _$GridFilterEditEvent {
  const factory GridFilterEditEvent.initial() = _Initial;
  const factory GridFilterEditEvent.didReceiveFilters(List<FilterPB> filters) =
      _DidReceiveFilters;

  const factory GridFilterEditEvent.deleteFilter({
    required String fieldId,
    required String filterId,
    required FieldType fieldType,
  }) = _DeleteFilter;

  const factory GridFilterEditEvent.createTextFilter({
    required String fieldId,
    required TextFilterCondition condition,
    required String content,
  }) = _CreateTextFilter;

  const factory GridFilterEditEvent.createCheckboxFilter({
    required String fieldId,
    required CheckboxFilterCondition condition,
  }) = _CreateCheckboxFilter;

  const factory GridFilterEditEvent.createNumberFilter({
    required String fieldId,
    required NumberFilterCondition condition,
    required String content,
  }) = _CreateNumberFilter;

  const factory GridFilterEditEvent.createDateFilter({
    required String fieldId,
    required DateFilterCondition condition,
    required int start,
  }) = _CreateDateFilter;

  const factory GridFilterEditEvent.createDateFilterInRange({
    required String fieldId,
    required DateFilterCondition condition,
    required int start,
    required int end,
  }) = _CreateDateFilterInRange;
}

@freezed
class GridFilterEditState with _$GridFilterEditState {
  const factory GridFilterEditState({
    required List<FilterPB> filters,
  }) = _GridFilterState;

  factory GridFilterEditState.initial() => const GridFilterEditState(
        filters: [],
      );
}
