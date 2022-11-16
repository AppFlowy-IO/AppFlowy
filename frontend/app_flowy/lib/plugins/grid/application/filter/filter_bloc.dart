import 'package:app_flowy/plugins/grid/application/filter/filter_listener.dart';
import 'package:flowy_sdk/log.dart';
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

part 'filter_bloc.freezed.dart';

class GridFilterBloc extends Bloc<GridFilterEvent, GridFilterState> {
  final String viewId;
  final FilterFFIService _ffiService;
  final FilterListener _listener;
  GridFilterBloc({required this.viewId})
      : _ffiService = FilterFFIService(viewId: viewId),
        _listener = FilterListener(viewId: viewId),
        super(GridFilterState.initial()) {
    on<GridFilterEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
            await _loadFilters();
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
    _listener.start(onFilterChanged: (result) {
      result.fold(
        (changeset) {
          final List<FilterPB> filters = List.from(state.filters);

          // Deletes the filters
          final deleteFilterIds =
              changeset.deleteFilters.map((e) => e.id).toList();
          filters.retainWhere(
            (element) => !deleteFilterIds.contains(element.id),
          );

          // Inserts the new fitler if it's not exist
          for (final newFilter in changeset.insertFilters) {
            final index =
                filters.indexWhere((element) => element.id == newFilter.id);
            if (index == -1) {
              filters.add(newFilter);
            }
          }

          if (!isClosed) {
            add(GridFilterEvent.didReceiveFilters(filters));
          }
        },
        (err) => Log.error(err),
      );
    });
  }

  Future<void> _loadFilters() async {
    final result = await _ffiService.getAllFilters();
    result.fold(
      (filters) {
        if (!isClosed) {
          add(GridFilterEvent.didReceiveFilters(filters));
        }
      },
      (err) => Log.error(err),
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class GridFilterEvent with _$GridFilterEvent {
  const factory GridFilterEvent.initial() = _Initial;
  const factory GridFilterEvent.didReceiveFilters(List<FilterPB> filters) =
      _DidReceiveFilters;

  const factory GridFilterEvent.deleteFilter({
    required String fieldId,
    required String filterId,
    required FieldType fieldType,
  }) = _DeleteFilter;

  const factory GridFilterEvent.createTextFilter({
    required String fieldId,
    required TextFilterCondition condition,
    required String content,
  }) = _CreateTextFilter;

  const factory GridFilterEvent.createCheckboxFilter({
    required String fieldId,
    required CheckboxFilterCondition condition,
  }) = _CreateCheckboxFilter;

  const factory GridFilterEvent.createNumberFilter({
    required String fieldId,
    required NumberFilterCondition condition,
    required String content,
  }) = _CreateCheckboxFitler;

  const factory GridFilterEvent.createDateFilter({
    required String fieldId,
    required DateFilterCondition condition,
    required int start,
  }) = _CreateDateFitler;

  const factory GridFilterEvent.createDateFilterInRange({
    required String fieldId,
    required DateFilterCondition condition,
    required int start,
    required int end,
  }) = _CreateDateFitlerInRange;
}

@freezed
class GridFilterState with _$GridFilterState {
  const factory GridFilterState({
    required List<FilterPB> filters,
  }) = _GridFilterState;

  factory GridFilterState.initial() => const GridFilterState(
        filters: [],
      );
}
