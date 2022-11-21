import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'filter_menu_bloc.freezed.dart';

class GridFilterMenuBloc
    extends Bloc<GridFilterMenuEvent, GridFilterMenuState> {
  final String viewId;
  final GridFieldController fieldController;
  void Function(List<FilterPB>)? _onFilterFn;

  GridFilterMenuBloc({required this.viewId, required this.fieldController})
      : super(GridFilterMenuState.initial(
          viewId,
          fieldController.filterInfos,
          fieldController.fieldInfos,
        )) {
    on<GridFilterMenuEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          toggleMenu: () {
            final isVisible = !state.isVisible;
            emit(state.copyWith(isVisible: isVisible));
          },
          didReceiveFields: (List<GridFieldInfo> fields) {
            emit(state.copyWith(fields: fields));
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(GridFilterMenuEvent.didReceiveFilters(filters));
    };

    fieldController.addListener(onFilters: (filters) {
      _onFilterFn?.call(filters);
    });
  }

  @override
  Future<void> close() {
    if (_onFilterFn != null) {
      fieldController.removeListener(onFiltersListener: _onFilterFn!);
      _onFilterFn = null;
    }
    return super.close();
  }
}

@freezed
class GridFilterMenuEvent with _$GridFilterMenuEvent {
  const factory GridFilterMenuEvent.initial() = _Initial;
  const factory GridFilterMenuEvent.didReceiveFilters(List<FilterPB> filters) =
      _DidReceiveFilters;
  const factory GridFilterMenuEvent.didReceiveFields(
      List<GridFieldInfo> fields) = _DidReceiveFields;
  const factory GridFilterMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class GridFilterMenuState with _$GridFilterMenuState {
  const factory GridFilterMenuState({
    required String viewId,
    required List<FilterPB> filters,
    required List<GridFieldInfo> fields,
    required bool isVisible,
  }) = _GridFilterMenuState;

  factory GridFilterMenuState.initial(
    String viewId,
    List<FilterPB> filterInfos,
    List<GridFieldInfo> fields,
  ) =>
      GridFilterMenuState(
        viewId: viewId,
        filters: filterInfos,
        fields: fields,
        isVisible: false,
      );
}
