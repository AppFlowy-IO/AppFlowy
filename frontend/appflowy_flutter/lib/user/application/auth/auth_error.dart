import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class AuthError {
  static final signInWithOauthError = FlowyError()
    ..msg = 'sign in with oauth error -10003'
    ..code = ErrorCode.UserUnauthorized;

  static final emptyDeepLink = FlowyError()
    ..msg = 'Unexpected empty DeepLink'
    ..code = ErrorCode.UnexpectedCalendarFieldType;

  static final deepLinkError = FlowyError()
    ..msg = 'DeepLink error'
    ..code = ErrorCode.Internal;

  static final unableToGetDeepLink = FlowyError()
    ..msg = 'Unable to get the deep link'
    ..code = ErrorCode.Internal;
}
