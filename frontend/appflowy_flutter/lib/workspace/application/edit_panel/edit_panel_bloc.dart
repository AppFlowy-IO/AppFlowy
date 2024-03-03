import 'package:appflowy/workspace/application/edit_panel/edit_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_panel_bloc.freezed.dart';

class EditPanelBloc extends Bloc<EditPanelEvent, EditPanelState> {
  EditPanelBloc() : super(EditPanelState.initial()) {
    on<EditPanelEvent>((event, emit) async {
      await event.map(
        startEdit: (e) async {
          emit(state.copyWith(isEditing: true, editContext: e.context));
        },
        endEdit: (value) async {
          emit(state.copyWith(isEditing: false, editContext: null));
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
    required EditPanelContext? editContext,
  }) = _EditPanelState;

  factory EditPanelState.initial() => const EditPanelState(
        isEditing: false,
        editContext: null,
      );
}
