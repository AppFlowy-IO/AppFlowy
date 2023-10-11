import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_filter_bloc.freezed.dart';

class NotificationFilterBloc
    extends Bloc<NotificationFilterEvent, NotificationFilterState> {
  NotificationFilterBloc() : super(const NotificationFilterState()) {
    on<NotificationFilterEvent>((event, emit) async {
      event.when(
        reset: () => emit(const NotificationFilterState()),
        changeSortBy: (NotificationSortOption sortBy) => emit(
          state.copyWith(sortBy: sortBy),
        ),
        toggleGroupByDate: () => emit(
          state.copyWith(groupByDate: !state.groupByDate),
        ),
        toggleShowUnreadsOnly: () => emit(
          state.copyWith(showUnreadsOnly: !state.showUnreadsOnly),
        ),
      );
    });
  }
}

enum NotificationSortOption {
  descending,
  ascending,
}

@freezed
class NotificationFilterEvent with _$NotificationFilterEvent {
  const factory NotificationFilterEvent.toggleShowUnreadsOnly() =
      _ToggleShowUnreadsOnly;

  const factory NotificationFilterEvent.toggleGroupByDate() =
      _ToggleGroupByDate;

  const factory NotificationFilterEvent.changeSortBy(
    NotificationSortOption sortBy,
  ) = _ChangeSortBy;

  const factory NotificationFilterEvent.reset() = _Reset;
}

@freezed
class NotificationFilterState extends Equatable with _$NotificationFilterState {
  const NotificationFilterState._();

  const factory NotificationFilterState({
    @Default(false) bool showUnreadsOnly,
    @Default(false) bool groupByDate,
    @Default(NotificationSortOption.descending) NotificationSortOption sortBy,
  }) = _NotificationFilterState;

  // If state is not default values, then there are custom changes
  bool get hasFilters =>
      showUnreadsOnly != false ||
      groupByDate != false ||
      sortBy != NotificationSortOption.descending;

  @override
  List<Object?> get props => [showUnreadsOnly, groupByDate, sortBy];
}
