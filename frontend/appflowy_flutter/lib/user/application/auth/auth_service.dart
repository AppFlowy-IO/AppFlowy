import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:dartz/dartz.dart';

abstract class AuthService {
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
  });

  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
  });

  ///
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
  });

  /// Returns a default [UserProfilePB]
  Future<Either<FlowyError, UserProfilePB>> signUpAsAnonymousUser();

  ///
  Future<void> signOut();

  /// Returns [UserProfilePB] if the user has sign in, otherwise returns null.
  Future<Either<FlowyError, UserProfilePB>> getUser();
}
