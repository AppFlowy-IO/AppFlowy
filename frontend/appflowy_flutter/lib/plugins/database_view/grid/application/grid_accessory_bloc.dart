import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'grid_accessory_bloc.freezed.dart';

class GridAccessoryMenuBloc
    extends Bloc<GridAccessoryMenuEvent, GridAccessoryMenuState> {
  final String viewId;

  GridAccessoryMenuBloc({required this.viewId})
      : super(
          GridAccessoryMenuState.initial(
            viewId,
          ),
        ) {
    on<GridAccessoryMenuEvent>(
      (final event, final emit) async {
        event.when(
          initial: () {},
          toggleMenu: () {
            emit(state.copyWith(isVisible: !state.isVisible));
          },
        );
      },
    );
  }
}

@freezed
class GridAccessoryMenuEvent with _$GridAccessoryMenuEvent {
  const factory GridAccessoryMenuEvent.initial() = _Initial;
  const factory GridAccessoryMenuEvent.toggleMenu() = _MenuVisibleChange;
}

@freezed
class GridAccessoryMenuState with _$GridAccessoryMenuState {
  const factory GridAccessoryMenuState({
    required final String viewId,
    required final bool isVisible,
  }) = _GridAccessoryMenuState;

  factory GridAccessoryMenuState.initial(
    final String viewId,
  ) =>
      GridAccessoryMenuState(
        viewId: viewId,
        isVisible: false,
      );
}
