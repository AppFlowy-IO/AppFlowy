part of 'edit_pannel_bloc.dart';

@freezed
abstract class EditPannelEvent with _$EditPannelEvent {
  const factory EditPannelEvent.startEdit(EditPannelContext context) =
      _StartEdit;

  const factory EditPannelEvent.endEdit(EditPannelContext context) = _EndEdit;
}
