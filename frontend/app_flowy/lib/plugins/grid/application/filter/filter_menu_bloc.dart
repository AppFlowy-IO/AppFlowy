import 'package:app_flowy/plugins/grid/application/filter/filter_listener.dart';
import 'package:app_flowy/plugins/grid/application/grid_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_service.dart';

part 'filter_menu_bloc.freezed.dart';

class GridFilterMenuBloc
    extends Bloc<GridFilterMenuEvent, GridFilterMenuState> {
  final String viewId;
  final FilterFFIService _filterFFIService;
  final GridFFIService _gridFFIService;
  final FilterListener _listener;
  GridFilterMenuBloc({required this.viewId})
      : _filterFFIService = FilterFFIService(viewId: viewId),
        _gridFFIService = GridFFIService(gridId: viewId),
        _listener = FilterListener(viewId: viewId),
        super(GridFilterMenuState.initial(viewId)) {
    on<GridFilterMenuEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
            _loadFilters();
          },
          didReceiveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          toggleMenu: () {
            final isVisible = !state.isVisible;
            emit(state.copyWith(isVisible: isVisible));
          },
          didReceiveFields: (List<FieldPB> fields) {
            var filterMap = {};
            for (var filter in state.filters) {
              filterMap[filter.fieldId] = filter;
            }
            emit(
              state.copyWith(
                fields: fields
                    .map((field) => FilterPropertyInfo(
                        fieldPB: field, hasFilter: filterMap[field.id] != null))
                    .toList(),
              ),
            );
          },
          loadFields: () => _loadFields(),
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

          // Inserts the new filter if it's not exist
          for (final newFilter in changeset.insertFilters) {
            final index =
                filters.indexWhere((element) => element.id == newFilter.id);
            if (index == -1) {
              filters.add(newFilter);
            }
          }

          if (!isClosed) {
            add(GridFilterMenuEvent.didReceiveFilters(filters));
          }
        },
        (err) => Log.error(err),
      );
    });
  }

  Future<void> _loadFilters() async {
    final result = await _filterFFIService.getAllFilters();
    result.fold(
      (filters) {
        if (!isClosed) {
          add(GridFilterMenuEvent.didReceiveFilters(filters));
        }
      },
      (err) => Log.error(err),
    );
  }

  Future<void> _loadFields() async {
    final result = await _gridFFIService.getFields();
    result.fold(
      (fields) {
        if (!isClosed) {
          add(GridFilterMenuEvent.didReceiveFields(fields.items));
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
class GridFilterMenuEvent with _$GridFilterMenuEvent {
  const factory GridFilterMenuEvent.initial() = _Initial;
  const factory GridFilterMenuEvent.didReceiveFilters(List<FilterPB> filters) =
      _DidReceiveFilters;
  const factory GridFilterMenuEvent.didReceiveFields(List<FieldPB> fields) =
      _DidReceiveFields;
  const factory GridFilterMenuEvent.loadFields() = _LoadFields;
  const factory GridFilterMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class GridFilterMenuState with _$GridFilterMenuState {
  const factory GridFilterMenuState({
    required String viewId,
    required List<FilterPB> filters,
    required List<FilterPropertyInfo> fields,
    required bool isVisible,
  }) = _GridFilterMenuState;

  factory GridFilterMenuState.initial(String viewId) => GridFilterMenuState(
        viewId: viewId,
        filters: [],
        fields: [],
        isVisible: false,
      );
}

@freezed
class FilterPropertyInfo with _$FilterPropertyInfo {
  const factory FilterPropertyInfo({
    required FieldPB fieldPB,
    required bool hasFilter,
  }) = _FilterPropertyInfo;
}
