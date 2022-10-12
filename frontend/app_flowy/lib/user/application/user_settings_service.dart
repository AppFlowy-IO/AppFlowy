import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';

class SettingsFFIService {
  Future<AppearanceSettingsPB> getAppearanceSetting() async {
    final result = await UserEventGetAppearanceSetting().send();

    return result.fold(
      (AppearanceSettingsPB setting) {
        return setting;
      },
      (error) {
        throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty);
      },
    );
  }

  Future<Either<Unit, FlowyError>> setAppearanceSetting(
      AppearanceSettingsPB setting) {
    return UserEventSetAppearanceSetting(setting).send();
  }
}
