import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_filter_bloc.freezed.dart';

class NotificationFilterBloc
    extends Bloc<NotificationFilterEvent, NotificationFilterState> {
  NotificationFilterBloc() : super(const NotificationFilterState()) {
    on<NotificationFilterEvent>((event, emit) async {
      await event.when(
        update: (showUnreadsOnly, groupByDate, sortBy) async {
          emit(
            state.copyWith(
              showUnreadsOnly: showUnreadsOnly,
              groupByDate: groupByDate,
              sortBy: sortBy,
            ),
          );
        },
        reset: () {
          emit(const NotificationFilterState());
        },
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
  const factory NotificationFilterEvent.update({
    bool? showUnreadsOnly,
    bool? groupByDate,
    NotificationSortOption? sortBy,
  }) = _Update;

  const factory NotificationFilterEvent.reset() = _Reset;
}

class NotificationFilterState extends Equatable {
  const NotificationFilterState({
    this.showUnreadsOnly = false,
    this.groupByDate = false,
    this.sortBy = NotificationSortOption.descending,
  });

  final bool showUnreadsOnly;
  final bool groupByDate;
  final NotificationSortOption sortBy;

  // If state is not default values, then there are custom changes
  bool get hasFilters =>
      showUnreadsOnly != false ||
      groupByDate != false ||
      sortBy != NotificationSortOption.descending;

  NotificationFilterState copyWith({
    bool? showUnreadsOnly,
    bool? groupByDate,
    NotificationSortOption? sortBy,
  }) =>
      NotificationFilterState(
        showUnreadsOnly: showUnreadsOnly ?? this.showUnreadsOnly,
        groupByDate: groupByDate ?? this.groupByDate,
        sortBy: sortBy ?? this.sortBy,
      );

  @override
  List<Object?> get props => [showUnreadsOnly, groupByDate, sortBy];
}
