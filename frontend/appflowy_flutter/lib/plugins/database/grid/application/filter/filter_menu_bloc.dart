import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_menu_bloc.freezed.dart';

class DatabaseFilterMenuBloc
    extends Bloc<DatabaseFilterMenuEvent, DatabaseFilterMenuState> {
  DatabaseFilterMenuBloc({required this.viewId, required this.fieldController})
      : super(
          DatabaseFilterMenuState.initial(
            viewId,
            fieldController.filterInfos,
            fieldController.fieldInfos,
          ),
        ) {
    _dispatch();
  }

  final String viewId;
  final FieldController fieldController;
  void Function(List<FilterInfo>)? _onFilterFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  void _dispatch() {
    on<DatabaseFilterMenuEvent>(
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
          didReceiveFields: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                fields: fields,
                creatableFields: getCreatableFilter(fields),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(DatabaseFilterMenuEvent.didReceiveFilters(filters));
    };

    _onFieldFn = (fields) {
      add(DatabaseFilterMenuEvent.didReceiveFields(fields));
    };

    fieldController.addListener(
      onFilters: (filters) {
        _onFilterFn?.call(filters);
      },
      onReceiveFields: (fields) {
        _onFieldFn?.call(fields);
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onFilterFn != null) {
      fieldController.removeListener(onFiltersListener: _onFilterFn!);
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
class DatabaseFilterMenuEvent with _$DatabaseFilterMenuEvent {
  const factory DatabaseFilterMenuEvent.initial() = _Initial;
  const factory DatabaseFilterMenuEvent.didReceiveFilters(
    List<FilterInfo> filters,
  ) = _DidReceiveFilters;
  const factory DatabaseFilterMenuEvent.didReceiveFields(
    List<FieldInfo> fields,
  ) = _DidReceiveFields;
  const factory DatabaseFilterMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class DatabaseFilterMenuState with _$DatabaseFilterMenuState {
  const factory DatabaseFilterMenuState({
    required String viewId,
    required List<FilterInfo> filters,
    required List<FieldInfo> fields,
    required List<FieldInfo> creatableFields,
    required bool isVisible,
  }) = _DatabaseFilterMenuState;

  factory DatabaseFilterMenuState.initial(
    String viewId,
    List<FilterInfo> filterInfos,
    List<FieldInfo> fields,
  ) =>
      DatabaseFilterMenuState(
        viewId: viewId,
        filters: filterInfos,
        fields: fields,
        creatableFields: getCreatableFilter(fields),
        isVisible: false,
      );
}

List<FieldInfo> getCreatableFilter(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((element) => element.canCreateFilter);
  return creatableFields;
}
