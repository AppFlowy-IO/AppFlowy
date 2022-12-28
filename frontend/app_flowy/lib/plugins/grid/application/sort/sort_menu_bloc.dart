import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'sort_menu_bloc.freezed.dart';

class SortMenuBloc extends Bloc<SortMenuEvent, SortMenuState> {
  final String viewId;
  final GridFieldController fieldController;
  void Function(List<FilterInfo>)? _onFilterFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  SortMenuBloc({required this.viewId, required this.fieldController})
      : super(SortMenuState.initial(
          viewId,
          fieldController.filterInfos,
          fieldController.fieldInfos,
        )) {
    on<SortMenuEvent>(
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
                creatableFields: getCreatableSort(fields),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(SortMenuEvent.didReceiveFilters(filters));
    };

    _onFieldFn = (fields) {
      add(SortMenuEvent.didReceiveFields(fields));
    };

    fieldController.addListener(
      onFilters: (filters) {
        _onFilterFn?.call(filters);
      },
      onFields: (fields) {
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
class SortMenuEvent with _$SortMenuEvent {
  const factory SortMenuEvent.initial() = _Initial;
  const factory SortMenuEvent.didReceiveFilters(List<FilterInfo> filters) =
      _DidReceiveFilters;
  const factory SortMenuEvent.didReceiveFields(List<FieldInfo> fields) =
      _DidReceiveFields;
  const factory SortMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class SortMenuState with _$SortMenuState {
  const factory SortMenuState({
    required String viewId,
    required List<FilterInfo> filters,
    required List<FieldInfo> fields,
    required List<FieldInfo> creatableFields,
    required bool isVisible,
  }) = _SortMenuState;

  factory SortMenuState.initial(
    String viewId,
    List<FilterInfo> filterInfos,
    List<FieldInfo> fields,
  ) =>
      SortMenuState(
        viewId: viewId,
        filters: filterInfos,
        fields: fields,
        creatableFields: getCreatableSort(fields),
        isVisible: false,
      );
}

List<FieldInfo> getCreatableSort(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((element) => element.canCreateSort);
  return creatableFields;
}
