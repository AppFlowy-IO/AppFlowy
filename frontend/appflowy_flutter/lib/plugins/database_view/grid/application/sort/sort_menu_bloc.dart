import 'dart:async';

import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_controller.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sort_menu_bloc.freezed.dart';

class SortMenuBloc extends Bloc<SortMenuEvent, SortMenuState> {
  final String viewId;
  final SortController sortController;
  final FieldController fieldController;
  void Function(List<SortInfo>)? _onSortFn;
  void Function(List<FieldPB>)? _onFieldFn;

  SortMenuBloc({
    required this.viewId,
    required this.sortController,
    required this.fieldController,
  }) : super(
          SortMenuState.initial(
            viewId,
            sortController.sorts,
            fieldController.fields,
          ),
        ) {
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
          didReceiveFields: (List<FieldPB> fields) {
            fields.retainWhere((field) => field.canCreateSort);
            emit(
              state.copyWith(
                fields: fields,
                creatableFields: fields,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onSortFn = (sortInfos) {
      add(SortMenuEvent.didReceiveSortInfos(sortInfos));
    };

    _onFieldFn = (fields) {
      add(SortMenuEvent.didReceiveFields(fields));
    };

    sortController.addListener(onReceiveSorts: _onSortFn);

    fieldController.addListener(onReceiveFields: _onFieldFn);
  }

  @override
  Future<void> close() {
    if (_onSortFn != null) {
      sortController.removeListener(onSortsListener: _onSortFn!);
      _onSortFn = null;
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
  const factory SortMenuEvent.didReceiveFields(List<FieldPB> fields) =
      _DidReceiveFields;
  const factory SortMenuEvent.toggleMenu() = _SetMenuVisibility;
}

@freezed
class SortMenuState with _$SortMenuState {
  const factory SortMenuState({
    required String viewId,
    required List<SortInfo> sortInfos,
    required List<FieldPB> fields,
    required List<FieldPB> creatableFields,
    required bool isVisible,
  }) = _SortMenuState;

  factory SortMenuState.initial(
    String viewId,
    List<SortInfo> sortInfos,
    List<FieldPB> fields,
  ) {
    fields.retainWhere((field) => field.canCreateSort);
    return SortMenuState(
      viewId: viewId,
      sortInfos: sortInfos,
      fields: fields,
      creatableFields: fields,
      isVisible: false,
    );
  }
}
