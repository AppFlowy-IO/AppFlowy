import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';

class UserSettingsService {
  Future<AppearanceSettings> getAppearanceSettings() async {
    final result = await UserEventGetAppearanceSetting().send();

    return result.fold(
      (AppearanceSettings setting) {
        return setting;
      },
      (error) {
        throw FlowySDKException(ExceptionType.AppearanceSettingsIsEmpty);
      },
    );
  }

  Future<Either<Unit, FlowyError>> setAppearanceSettings(AppearanceSettings settings) {
    return UserEventSetAppearanceSetting(settings).send();
  }
}
