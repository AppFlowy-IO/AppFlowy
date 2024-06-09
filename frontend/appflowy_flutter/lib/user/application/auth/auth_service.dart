import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:appflowy_result/appflowy_result.dart';

class AuthServiceMapKeys {
  const AuthServiceMapKeys._();

  // for supabase auth use only.
  static const String uuid = 'uuid';
  static const String email = 'email';
  static const String deviceId = 'device_id';
  static const String signInURL = 'sign_in_url';
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
  /// - `params`: Additional parameters for authentication (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].

  Future<FlowyResult<UserProfilePB, FlowyError>> signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params,
  });

  /// Registers a new user with their name, email, and password.
  ///
  /// - `name`: The name of the user.
  /// - `email`: The email address of the user.
  /// - `password`: The password of the user.
  /// - `params`: Additional parameters for registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params,
  });

  /// Registers a new user with an OAuth platform.
  ///
  /// - `platform`: The OAuth platform name.
  /// - `params`: Additional parameters for OAuth registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    Map<String, String> params,
  });

  /// Registers a user as a guest.
  ///
  /// - `params`: Additional parameters for guest registration (optional).
  ///
  /// Returns a default [UserProfilePB].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpAsGuest({
    Map<String, String> params,
  });

  /// Authenticates a user with a magic link sent to their email.
  ///
  /// - `email`: The email address of the user.
  /// - `params`: Additional parameters for authentication with magic link (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<void, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Retrieves the currently authenticated user's profile.
  ///
  /// Returns [UserProfilePB] if the user has signed in, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser();
}
