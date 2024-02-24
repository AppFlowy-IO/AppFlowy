import 'dart:async';

import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_cubit.freezed.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit() : super(NotificationSettingsState.initial()) {
    UserSettingsBackendService()
        .getNotificationSettings()
        .then((notificationSettings) {
      _notificationSettings = notificationSettings;
      emit(
        state.copyWith(
          isNotificationsEnabled: _notificationSettings.notificationsEnabled,
        ),
      );
      _initCompleter.complete();
    });
  }

  final Completer<void> _initCompleter = Completer();

  late final NotificationSettingsPB _notificationSettings;

  Future<void> toggleNotificationsEnabled() async {
    await _initCompleter.future;

    _notificationSettings.notificationsEnabled = !state.isNotificationsEnabled;

    emit(
      state.copyWith(
        isNotificationsEnabled: _notificationSettings.notificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> _saveNotificationSettings() async {
    await _initCompleter.future;

    final result = await UserSettingsBackendService()
        .setNotificationSettings(_notificationSettings);
    result.fold(
      (r) => null,
      (error) => Log.error(error),
    );
  }
}

@freezed
class NotificationSettingsState with _$NotificationSettingsState {
  const NotificationSettingsState._();

  const factory NotificationSettingsState({
    required bool isNotificationsEnabled,
  }) = _NotificationSettingsState;

  factory NotificationSettingsState.initial() =>
      const NotificationSettingsState(isNotificationsEnabled: true);
}
