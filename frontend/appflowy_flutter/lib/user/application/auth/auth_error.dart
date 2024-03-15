import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class AuthError {
  static final supabaseSignInError = FlowyError()
    ..msg = 'supabase sign in error -10001'
    ..code = ErrorCode.UserUnauthorized;

  static final supabaseSignUpError = FlowyError()
    ..msg = 'supabase sign up error -10002'
    ..code = ErrorCode.UserUnauthorized;

  static final supabaseSignInWithOauthError = FlowyError()
    ..msg = 'supabase sign in with oauth error -10003'
    ..code = ErrorCode.UserUnauthorized;

  static final supabaseGetUserError = FlowyError()
    ..msg = 'unable to get user from supabase  -10004'
    ..code = ErrorCode.UserUnauthorized;

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
