import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../../application/field/field_controller.dart';
import '../../presentation/widgets/sort/sort_info.dart';
import 'util.dart';

part 'sort_menu_bloc.freezed.dart';

class SortMenuBloc extends Bloc<SortMenuEvent, SortMenuState> {
  final String viewId;
  final FieldController fieldController;
  void Function(List<SortInfo>)? _onSortChangeFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  SortMenuBloc({required this.viewId, required this.fieldController})
      : super(
          SortMenuState.initial(
            viewId,
            fieldController.sortInfos,
            fieldController.fieldInfos,
          ),
        ) {
    on<SortMenuEvent>(
      (final event, final emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveSortInfos: (final sortInfos) {
            emit(state.copyWith(sortInfos: sortInfos));
          },
          toggleMenu: () {
            final isVisible = !state.isVisible;
            emit(state.copyWith(isVisible: isVisible));
          },
          didReceiveFields: (final List<FieldInfo> fields) {
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
    _onSortChangeFn = (final sortInfos) {
      add(SortMenuEvent.didReceiveSortInfos(sortInfos));
    };

    _onFieldFn = (final fields) {
      add(SortMenuEvent.didReceiveFields(fields));
    };

    fieldController.addListener(
      onSorts: (final sortInfos) {
        _onSortChangeFn?.call(sortInfos);
      },
      onReceiveFields: (final fields) {
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
  const factory SortMenuEvent.didReceiveSortInfos(final List<SortInfo> sortInfos) =
      _DidReceiveSortInfos;
  const factory SortMenuEvent.didReceiveFields(final List<FieldInfo> fields) =
      _DidReceiveFields;
  const factory SortMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class SortMenuState with _$SortMenuState {
  const factory SortMenuState({
    required final String viewId,
    required final List<SortInfo> sortInfos,
    required final List<FieldInfo> fields,
    required final List<FieldInfo> creatableFields,
    required final bool isVisible,
  }) = _SortMenuState;

  factory SortMenuState.initial(
    final String viewId,
    final List<SortInfo> sortInfos,
    final List<FieldInfo> fields,
  ) =>
      SortMenuState(
        viewId: viewId,
        sortInfos: sortInfos,
        fields: fields,
        creatableFields: getCreatableSorts(fields),
        isVisible: false,
      );
}
