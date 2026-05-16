import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rename_view_bloc.freezed.dart';

class RenameViewBloc extends Bloc<RenameViewEvent, RenameViewState> {
  RenameViewBloc(PopoverController controller)
      : _controller = controller,
        super(RenameViewState(controller: controller)) {
    on<RenameViewEvent>((event, emit) {
      event.when(
        open: () => _controller.show(),
      );
    });
  }

  final PopoverController _controller;

  @override
  Future<void> close() async {
    _controller.close();
    await super.close();
  }
}

@freezed
class RenameViewEvent with _$RenameViewEvent {
  const factory RenameViewEvent.open() = _Open;
}

@freezed
class RenameViewState with _$RenameViewState {
  const factory RenameViewState({
    required PopoverController controller,
  }) = _RenameViewState;
}
