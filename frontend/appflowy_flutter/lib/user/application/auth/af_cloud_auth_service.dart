import 'dart:async';

import 'package:appflowy/user/application/auth/backend_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';

class AFCloudAuthService implements AuthService {
  AFCloudAuthService();

  final BackendAuthService _backendAuthService = BackendAuthService(
    AuthTypePB.AFCloud,
  );

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    Map<String, String> params = const {},
  }) async {
    //
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    await _backendAuthService.signOut();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    return _backendAuthService.signUpAsGuest();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }
}
