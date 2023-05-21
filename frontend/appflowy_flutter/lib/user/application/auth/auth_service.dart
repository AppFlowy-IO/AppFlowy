import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:dartz/dartz.dart';

class AuthServiceMapKeys {
  const AuthServiceMapKeys._();

  // for supabase auth use only.
  static const String uuid = 'uuid';
}

abstract class AuthService {
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    AuthTypePB authType,
    Map<String, String> map,
  });

  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    AuthTypePB authType,
    Map<String, String> map,
  });

  ///
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType,
    Map<String, String> map,
  });

  /// Returns a default [UserProfilePB]
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    AuthTypePB authType,
    Map<String, String> map,
  });

  ///
  Future<void> signOut({
    AuthTypePB authType,
  });

  /// Returns [UserProfilePB] if the user has sign in, otherwise returns null.
  Future<Either<FlowyError, UserProfilePB>> getUser();
}
