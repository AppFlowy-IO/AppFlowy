import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'filter_menu_bloc.freezed.dart';

class GridFilterMenuBloc
    extends Bloc<GridFilterMenuEvent, GridFilterMenuState> {
  final String viewId;
  final FieldController fieldController;
  void Function(List<FilterInfo>)? _onFilterFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  GridFilterMenuBloc({required this.viewId, required this.fieldController})
      : super(
          GridFilterMenuState.initial(
            viewId,
            fieldController.filterInfos,
            fieldController.fieldInfos,
          ),
        ) {
    on<GridFilterMenuEvent>(
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
      add(GridFilterMenuEvent.didReceiveFilters(filters));
    };

    _onFieldFn = (fields) {
      add(GridFilterMenuEvent.didReceiveFields(fields));
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
  Future<void> close() {
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
class GridFilterMenuEvent with _$GridFilterMenuEvent {
  const factory GridFilterMenuEvent.initial() = _Initial;
  const factory GridFilterMenuEvent.didReceiveFilters(
    List<FilterInfo> filters,
  ) = _DidReceiveFilters;
  const factory GridFilterMenuEvent.didReceiveFields(List<FieldInfo> fields) =
      _DidReceiveFields;
  const factory GridFilterMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class GridFilterMenuState with _$GridFilterMenuState {
  const factory GridFilterMenuState({
    required String viewId,
    required List<FilterInfo> filters,
    required List<FieldInfo> fields,
    required List<FieldInfo> creatableFields,
    required bool isVisible,
  }) = _GridFilterMenuState;

  factory GridFilterMenuState.initial(
    String viewId,
    List<FilterInfo> filterInfos,
    List<FieldInfo> fields,
  ) =>
      GridFilterMenuState(
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
