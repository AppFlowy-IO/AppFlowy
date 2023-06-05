import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';
import 'package:dartz/dartz.dart';
part 'edit_select_option_bloc.freezed.dart';

class EditSelectOptionBloc
    extends Bloc<EditSelectOptionEvent, EditSelectOptionState> {
  EditSelectOptionBloc({required final SelectOptionPB option})
      : super(EditSelectOptionState.initial(option)) {
    on<EditSelectOptionEvent>(
      (final event, final emit) async {
        event.map(
          updateName: (final _UpdateName value) {
            emit(state.copyWith(option: _updateName(value.name)));
          },
          updateColor: (final _UpdateColor value) {
            emit(state.copyWith(option: _updateColor(value.color)));
          },
          delete: (final _Delete value) {
            emit(state.copyWith(deleted: const Some(true)));
          },
        );
      },
    );
  }

  SelectOptionPB _updateColor(final SelectOptionColorPB color) {
    state.option.freeze();
    return state.option.rebuild((final option) {
      option.color = color;
    });
  }

  SelectOptionPB _updateName(final String name) {
    state.option.freeze();
    return state.option.rebuild((final option) {
      option.name = name;
    });
  }
}

@freezed
class EditSelectOptionEvent with _$EditSelectOptionEvent {
  const factory EditSelectOptionEvent.updateName(final String name) = _UpdateName;
  const factory EditSelectOptionEvent.updateColor(final SelectOptionColorPB color) =
      _UpdateColor;
  const factory EditSelectOptionEvent.delete() = _Delete;
}

@freezed
class EditSelectOptionState with _$EditSelectOptionState {
  const factory EditSelectOptionState({
    required final SelectOptionPB option,
    required final Option<bool> deleted,
  }) = _EditSelectOptionState;

  factory EditSelectOptionState.initial(final SelectOptionPB option) =>
      EditSelectOptionState(
        option: option,
        deleted: none(),
      );
}
