import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/sort/sort_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'util.dart';

part 'sort_menu_bloc.freezed.dart';

class SortMenuBloc extends Bloc<SortMenuEvent, SortMenuState> {
  final String viewId;
  final GridFieldController fieldController;
  void Function(List<SortInfo>)? _onSortChangeFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  SortMenuBloc({required this.viewId, required this.fieldController})
      : super(SortMenuState.initial(
          viewId,
          fieldController.sortInfos,
          fieldController.fieldInfos,
        )) {
    on<SortMenuEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveSortInfos: (sortInfos) {
            emit(state.copyWith(sortInfos: sortInfos));
          },
          toggleMenu: () {
            final isVisible = !state.isVisible;
            emit(state.copyWith(isVisible: isVisible));
          },
          didReceiveFields: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                fields: fields,
                creatableFields: getCreatableSorts(fields),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onSortChangeFn = (sortInfos) {
      add(SortMenuEvent.didReceiveSortInfos(sortInfos));
    };

    _onFieldFn = (fields) {
      add(SortMenuEvent.didReceiveFields(fields));
    };

    fieldController.addListener(
      onSorts: (sortInfos) {
        _onSortChangeFn?.call(sortInfos);
      },
      onFields: (fields) {
        _onFieldFn?.call(fields);
      },
    );
  }

  @override
  Future<void> close() {
    if (_onSortChangeFn != null) {
      fieldController.removeListener(onSortsListener: _onSortChangeFn!);
      _onSortChangeFn = null;
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
  const factory SortMenuEvent.didReceiveSortInfos(List<SortInfo> sortInfos) =
      _DidReceiveSortInfos;
  const factory SortMenuEvent.didReceiveFields(List<FieldInfo> fields) =
      _DidReceiveFields;
  const factory SortMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class SortMenuState with _$SortMenuState {
  const factory SortMenuState({
    required String viewId,
    required List<SortInfo> sortInfos,
    required List<FieldInfo> fields,
    required List<FieldInfo> creatableFields,
    required bool isVisible,
  }) = _SortMenuState;

  factory SortMenuState.initial(
    String viewId,
    List<SortInfo> sortInfos,
    List<FieldInfo> fields,
  ) =>
      SortMenuState(
        viewId: viewId,
        sortInfos: sortInfos,
        fields: fields,
        creatableFields: getCreatableSorts(fields),
        isVisible: false,
      );
}
