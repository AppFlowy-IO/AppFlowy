import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:easy_localization/easy_localization.dart';

class AFPasswordErrorExtension {
  static final RegExp incorrectPasswordPattern =
      RegExp('Incorrect current password');
  static final RegExp tooShortPasswordPattern =
      RegExp(r'Password should be at least (\d+) characters');
  static final RegExp tooLongPasswordPattern =
      RegExp(r'Password cannot be longer than (\d+) characters');

  static String getErrorMessage(FlowyError error) {
    final msg = error.msg;
    if (incorrectPasswordPattern.hasMatch(msg)) {
      return LocaleKeys
          .newSettings_myAccount_password_error_currentPasswordIsIncorrect
          .tr();
    } else if (tooShortPasswordPattern.hasMatch(msg)) {
      return LocaleKeys
          .newSettings_myAccount_password_error_passwordShouldBeAtLeast6Characters
          .tr(
        namedArgs: {
          'min': tooShortPasswordPattern.firstMatch(msg)?.group(1) ?? '6',
        },
      );
    } else if (tooLongPasswordPattern.hasMatch(msg)) {
      return LocaleKeys
          .newSettings_myAccount_password_error_passwordCannotBeLongerThan72Characters
          .tr(
        namedArgs: {
          'max': tooLongPasswordPattern.firstMatch(msg)?.group(1) ?? '72',
        },
      );
    }

    return msg;
  }
}
