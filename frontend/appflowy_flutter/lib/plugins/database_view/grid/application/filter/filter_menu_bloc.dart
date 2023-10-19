import 'dart:async';

import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_extension.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_controller.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_menu_bloc.freezed.dart';

class FilterMenuBloc extends Bloc<FilterMenuEvent, FilterMenuState> {
  final String viewId;
  final FilterController filterController;
  void Function(List<FilterInfo>)? _onFilterFn;
  void Function(List<FieldPB>)? _onFieldFn;

  FieldController get fieldController => filterController.fieldController;

  FilterMenuBloc({
    required this.viewId,
    required this.filterController,
  }) : super(
          FilterMenuState.initial(
            viewId,
            filterController.filters,
            filterController.fieldController.fields,
          ),
        ) {
    on<FilterMenuEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          toggleMenu: () {
            final isVisible = !state.isVisible;
            emit(state.copyWith(isVisible: isVisible));
          },
          didReceiveFields: (fields) {
            final newFields = List<FieldPB>.from(fields);
            emit(
              state.copyWith(
                fields: fields,
                creatableFields: getCreatableFilter(newFields),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(FilterMenuEvent.didReceiveFilters(filters));
    };

    _onFieldFn = (fields) {
      add(FilterMenuEvent.didReceiveFields(fields));
    };

    filterController.addListener(
      onReceiveFilters: (filters) {
        _onFilterFn?.call(filters);
      },
    );
    fieldController.addListener(
      onReceiveFields: (fields) {
        _onFieldFn?.call(fields);
      },
    );
  }

  @override
  Future<void> close() {
    if (_onFilterFn != null) {
      filterController.removeListener(onFiltersListener: _onFilterFn!);
      _onFilterFn = null;
    }
    if (_onFieldFn != null) {
      fieldController.removeListener(onFieldsListener: _onFieldFn!);
      _onFieldFn = null;
    }
    return super.close();
  }
}

@freezed
class FilterMenuEvent with _$FilterMenuEvent {
  const factory FilterMenuEvent.initial() = _Initial;
  const factory FilterMenuEvent.didReceiveFilters(
    List<FilterInfo> filters,
  ) = _DidReceiveFilters;
  const factory FilterMenuEvent.didReceiveFields(List<FieldPB> fields) =
      _DidReceiveFields;
  const factory FilterMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class FilterMenuState with _$FilterMenuState {
  const factory FilterMenuState({
    required String viewId,
    required List<FilterInfo> filters,
    required List<FieldPB> fields,
    required List<FieldPB> creatableFields,
    required bool isVisible,
  }) = _FilterMenuState;

  factory FilterMenuState.initial(
    String viewId,
    List<FilterInfo> filterInfos,
    List<FieldPB> fields,
  ) =>
      FilterMenuState(
        viewId: viewId,
        filters: filterInfos,
        fields: fields,
        creatableFields: getCreatableFilter(fields),
        isVisible: false,
      );
}

List<FieldPB> getCreatableFilter(List<FieldPB> fields) {
  fields.retainWhere((element) => element.canCreateFilter);
  return fields;
}
