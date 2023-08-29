import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:dartz/dartz.dart';

class AuthServiceMapKeys {
  const AuthServiceMapKeys._();

  // for supabase auth use only.
  static const String uuid = 'uuid';
  static const String email = 'email';
  static const String deviceId = 'device_id';
}

/// `AuthService` is an abstract class that defines methods related to user authentication.
///
/// This service provides various methods for user sign-in, sign-up,
/// OAuth-based registration, and other related functionalities.
abstract class AuthService {
  /// Authenticates a user with their email and password.
  ///
  /// - `email`: The email address of the user.
  /// - `password`: The password of the user.
  /// - `authType`: The type of authentication (optional).
  /// - `params`: Additional parameters for authentication (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].

  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    AuthTypePB authType,
    Map<String, String> params,
  });

  /// Registers a new user with their name, email, and password.
  ///
  /// - `name`: The name of the user.
  /// - `email`: The email address of the user.
  /// - `password`: The password of the user.
  /// - `authType`: The type of authentication (optional).
  /// - `params`: Additional parameters for registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    AuthTypePB authType,
    Map<String, String> params,
  });

  /// Registers a new user with an OAuth platform.
  ///
  /// - `platform`: The OAuth platform name.
  /// - `authType`: The type of authentication (optional).
  /// - `params`: Additional parameters for OAuth registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType,
    Map<String, String> params,
  });

  /// Registers a user as a guest.
  ///
  /// - `authType`: The type of authentication (optional).
  /// - `params`: Additional parameters for guest registration (optional).
  ///
  /// Returns a default [UserProfilePB].
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    AuthTypePB authType,
    Map<String, String> params,
  });

  /// Authenticates a user with a magic link sent to their email.
  ///
  /// - `email`: The email address of the user.
  /// - `params`: Additional parameters for authentication with magic link (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> signInWithMagicLink({
    required String email,
    Map<String, String> params,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Retrieves the currently authenticated user's profile.
  ///
  /// Returns [UserProfilePB] if the user has signed in, otherwise returns [FlowyError].
  Future<Either<FlowyError, UserProfilePB>> getUser();
}
