import 'package:app_flowy/workspace/application/edit_panel/edit_context.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'edit_panel_bloc.freezed.dart';

class EditPanelBloc extends Bloc<EditPanelEvent, EditPanelState> {
  EditPanelBloc() : super(EditPanelState.initial()) {
    on<EditPanelEvent>((event, emit) async {
      await event.map(
        startEdit: (e) async {
          emit(state.copyWith(isEditing: true, editContext: some(e.context)));
        },
        endEdit: (value) async {
          emit(state.copyWith(isEditing: false, editContext: none()));
        },
      );
    });
  }
}

@freezed
class EditPanelEvent with _$EditPanelEvent {
  const factory EditPanelEvent.startEdit(EditPanelContext context) = _StartEdit;

  const factory EditPanelEvent.endEdit(EditPanelContext context) = _EndEdit;
}

@freezed
class EditPanelState with _$EditPanelState {
  const factory EditPanelState({
    required bool isEditing,
    required Option<EditPanelContext> editContext,
  }) = _EditPanelState;

  factory EditPanelState.initial() => EditPanelState(
        isEditing: false,
        editContext: none(),
      );
}
