import 'package:appflowy/workspace/application/edit_panel/edit_context.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'edit_panel_bloc.freezed.dart';

class EditPanelBloc extends Bloc<EditPanelEvent, EditPanelState> {
  EditPanelBloc() : super(EditPanelState.initial()) {
    on<EditPanelEvent>((final event, final emit) async {
      await event.map(
        startEdit: (final e) async {
          emit(state.copyWith(isEditing: true, editContext: some(e.context)));
        },
        endEdit: (final value) async {
          emit(state.copyWith(isEditing: false, editContext: none()));
        },
      );
    });
  }
}

@freezed
class EditPanelEvent with _$EditPanelEvent {
  const factory EditPanelEvent.startEdit(final EditPanelContext context) = _StartEdit;

  const factory EditPanelEvent.endEdit(final EditPanelContext context) = _EndEdit;
}

@freezed
class EditPanelState with _$EditPanelState {
  const factory EditPanelState({
    required final bool isEditing,
    required final Option<EditPanelContext> editContext,
  }) = _EditPanelState;

  factory EditPanelState.initial() => EditPanelState(
        isEditing: false,
        editContext: none(),
      );
}
