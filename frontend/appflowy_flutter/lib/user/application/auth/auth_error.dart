import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class AuthError {
  static final supabaseSignInError = FlowyError()
    ..msg = 'supabase sign in error'
    ..code = -10001;

  static final supabaseSignUpError = FlowyError()
    ..msg = 'supabase sign up error'
    ..code = -10002;

  static final supabaseSignInWithOauthError = FlowyError()
    ..msg = 'supabase sign in with oauth error'
    ..code = -10003;

  static final supabaseGetUserError = FlowyError()
    ..msg = 'supabase sign in with oauth error'
    ..code = -10003;
}
