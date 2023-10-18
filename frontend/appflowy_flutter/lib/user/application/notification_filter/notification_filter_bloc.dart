import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_filter_bloc.freezed.dart';

class NotificationFilterBloc
    extends Bloc<NotificationFilterEvent, NotificationFilterState> {
  NotificationFilterBloc() : super(const NotificationFilterState()) {
    on<NotificationFilterEvent>((event, emit) async {
      event.when(
        reset: () => emit(const NotificationFilterState()),
        toggleShowUnreadsOnly: () => emit(
          state.copyWith(showUnreadsOnly: !state.showUnreadsOnly),
        ),
      );
    });
  }
}

@freezed
class NotificationFilterEvent with _$NotificationFilterEvent {
  const factory NotificationFilterEvent.toggleShowUnreadsOnly() =
      _ToggleShowUnreadsOnly;

  const factory NotificationFilterEvent.reset() = _Reset;
}

@freezed
class NotificationFilterState with _$NotificationFilterState {
  const NotificationFilterState._();

  const factory NotificationFilterState({
    @Default(false) bool showUnreadsOnly,
  }) = _NotificationFilterState;

  // If state is not default values, then there are custom changes
  bool get hasFilters => showUnreadsOnly != false;
}
