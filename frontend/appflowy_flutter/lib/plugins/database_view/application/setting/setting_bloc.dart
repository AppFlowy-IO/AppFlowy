import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'setting_bloc.freezed.dart';

class DatabaseSettingBloc
    extends Bloc<DatabaseSettingEvent, DatabaseSettingState> {
  final String viewId;
  DatabaseSettingBloc({required this.viewId})
      : super(DatabaseSettingState.initial()) {
    on<DatabaseSettingEvent>(
      (event, emit) async {
        event.map(
          performAction: (_PerformAction value) {
            emit(state.copyWith(selectedAction: Some(value.action)));
          },
        );
      },
    );
  }
}

@freezed
class DatabaseSettingEvent with _$DatabaseSettingEvent {
  const factory DatabaseSettingEvent.performAction(
    DatabaseSettingAction action,
  ) = _PerformAction;
}

@freezed
class DatabaseSettingState with _$DatabaseSettingState {
  const factory DatabaseSettingState({
    required Option<DatabaseSettingAction> selectedAction,
  }) = _DatabaseSettingState;

  factory DatabaseSettingState.initial() => DatabaseSettingState(
        selectedAction: none(),
      );
}

enum DatabaseSettingAction {
  showProperties,
  showLayout,
  showGroup,
  showCalendarLayout,
}

extension DatabaseSettingActionExtension on DatabaseSettingAction {
  String iconName() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return 'grid/setting/properties';
      case DatabaseSettingAction.showLayout:
        return 'grid/setting/database_layout';
      case DatabaseSettingAction.showGroup:
        return 'grid/setting/group';
      case DatabaseSettingAction.showCalendarLayout:
        return 'grid/setting/calendar_layout';
    }
  }

  String title() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return LocaleKeys.grid_settings_Properties.tr();
      case DatabaseSettingAction.showLayout:
        return LocaleKeys.grid_settings_databaseLayout.tr();
      case DatabaseSettingAction.showGroup:
        return LocaleKeys.grid_settings_group.tr();
      case DatabaseSettingAction.showCalendarLayout:
        return LocaleKeys.calendar_settings_name.tr();
    }
  }
}

/// Returns the list of actions that should be shown for the given database layout.
List<DatabaseSettingAction> actionsForDatabaseLayout(DatabaseLayoutPB? layout) {
  switch (layout) {
    case DatabaseLayoutPB.Board:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        DatabaseSettingAction.showGroup,
      ];
    case DatabaseLayoutPB.Calendar:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        DatabaseSettingAction.showCalendarLayout,
      ];
    case DatabaseLayoutPB.Grid:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
      ];
    default:
      return [];
  }
}
