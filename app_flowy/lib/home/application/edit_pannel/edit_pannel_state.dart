part of 'edit_pannel_bloc.dart';

@freezed
abstract class EditPannelState implements _$EditPannelState {
  const factory EditPannelState({
    required bool isEditing,
    required Option<EditPannelContext> editContext,
  }) = _EditPannelState;

  factory EditPannelState.initial() => EditPannelState(
        isEditing: false,
        editContext: none(),
      );
}
