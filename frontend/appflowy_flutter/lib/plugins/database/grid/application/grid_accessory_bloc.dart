import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'grid_accessory_bloc.freezed.dart';

class DatabaseViewSettingExtensionBloc extends Bloc<
    DatabaseViewSettingExtensionEvent, DatabaseViewSettingExtensionState> {
  DatabaseViewSettingExtensionBloc({required this.viewId})
      : super(DatabaseViewSettingExtensionState.initial(viewId)) {
    on<DatabaseViewSettingExtensionEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
          toggleMenu: () {
            emit(state.copyWith(isVisible: !state.isVisible));
          },
        );
      },
    );
  }

  final String viewId;
}

@freezed
class DatabaseViewSettingExtensionEvent
    with _$DatabaseViewSettingExtensionEvent {
  const factory DatabaseViewSettingExtensionEvent.initial() = _Initial;
  const factory DatabaseViewSettingExtensionEvent.toggleMenu() =
      _MenuVisibleChange;
}

@freezed
class DatabaseViewSettingExtensionState
    with _$DatabaseViewSettingExtensionState {
  const factory DatabaseViewSettingExtensionState({
    required String viewId,
    required bool isVisible,
  }) = _DatabaseViewSettingExtensionState;

  factory DatabaseViewSettingExtensionState.initial(
    String viewId,
  ) =>
      DatabaseViewSettingExtensionState(
        viewId: viewId,
        isVisible: false,
      );
}
