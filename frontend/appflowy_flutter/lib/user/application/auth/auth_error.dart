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

  static final emptyDeeplink = FlowyError()
    ..msg = 'Unexpected empty deeplink'
    ..code = ErrorCode.UnexpectedEmpty;

  static final deeplinkError = FlowyError()
    ..msg = 'Deeplink error'
    ..code = ErrorCode.Internal;
}
