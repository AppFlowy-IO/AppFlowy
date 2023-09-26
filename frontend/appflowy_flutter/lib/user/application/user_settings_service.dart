import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';

class UserSettingsBackendService {
  Future<AppearanceSettingsPB> getAppearanceSetting() async {
    final result = await UserEventGetAppearanceSetting().send();

    return result.fold(
      (AppearanceSettingsPB setting) => setting,
      (error) =>
          throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty),
    );
  }

  Future<Either<UserSettingPB, FlowyError>> getUserSetting() {
    return UserEventGetUserSetting().send();
  }

  Future<Either<Unit, FlowyError>> setAppearanceSetting(
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

  Future<Either<FlowyError, Unit>> setDateTimeSettings(
    DateTimeSettingsPB settings,
  ) async {
    return (await UserEventSetDateTimeSettings(settings).send()).swap();
  }
}
