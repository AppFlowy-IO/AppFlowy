import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'edit_select_option_bloc.freezed.dart';

class EditSelectOptionBloc
    extends Bloc<EditSelectOptionEvent, EditSelectOptionState> {
  EditSelectOptionBloc({required SelectOptionPB option})
      : super(EditSelectOptionState.initial(option)) {
    on<EditSelectOptionEvent>(
      (event, emit) async {
        event.when(
          updateName: (name) {
            emit(state.copyWith(option: _updateName(name)));
          },
          updateColor: (color) {
            emit(state.copyWith(option: _updateColor(color)));
          },
          delete: () {
            emit(state.copyWith(deleted: true));
          },
        );
      },
    );
  }

  SelectOptionPB _updateColor(SelectOptionColorPB color) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.color = color;
    });
  }

  SelectOptionPB _updateName(String name) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.name = name;
    });
  }
}

@freezed
class EditSelectOptionEvent with _$EditSelectOptionEvent {
  const factory EditSelectOptionEvent.updateName(String name) = _UpdateName;
  const factory EditSelectOptionEvent.updateColor(SelectOptionColorPB color) =
      _UpdateColor;
  const factory EditSelectOptionEvent.delete() = _Delete;
}

@freezed
class EditSelectOptionState with _$EditSelectOptionState {
  const factory EditSelectOptionState({
    required SelectOptionPB option,
    required bool deleted,
  }) = _EditSelectOptionState;

  factory EditSelectOptionState.initial(SelectOptionPB option) =>
      EditSelectOptionState(
        option: option,
        deleted: false,
      );
}
