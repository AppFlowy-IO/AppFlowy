import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class UserSettingsBackendService {
  Future<AppearanceSettingsPB> getAppearanceSetting() async {
    final result = await UserEventGetAppearanceSetting().send();

    return result.fold(
      (AppearanceSettingsPB setting) => setting,
      (error) =>
          throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty),
    );
  }

  Future<FlowyResult<UserSettingPB, FlowyError>> getUserSetting() {
    return UserEventGetUserSetting().send();
  }

  Future<FlowyResult<void, FlowyError>> setAppearanceSetting(
    AppearanceSettingsPB setting,
  ) {
    return UserEventSetAppearanceSetting(setting).send();
  }

  Future<DateTimeSettingsPB> getDateTimeSettings() async {
    final result = await UserEventGetDateTimeSettings().send();

    return result.fold(
      (DateTimeSettingsPB setting) => setting,
      (error) =>
          throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty),
    );
  }

  Future<FlowyResult<void, FlowyError>> setDateTimeSettings(
    DateTimeSettingsPB settings,
  ) async {
    return UserEventSetDateTimeSettings(settings).send();
  }

  Future<FlowyResult<void, FlowyError>> setNotificationSettings(
    NotificationSettingsPB settings,
  ) async {
    return UserEventSetNotificationSettings(settings).send();
  }

  Future<NotificationSettingsPB> getNotificationSettings() async {
    final result = await UserEventGetNotificationSettings().send();

    return result.fold(
      (NotificationSettingsPB setting) => setting,
      (error) =>
          throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty),
    );
  }
}
