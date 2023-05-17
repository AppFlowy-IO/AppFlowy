import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService implements AuthService {
  const SupabaseAuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      // TODO: handle error
      return left(FlowyError());
    }
    return Right(user.toUserProfile());
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .then((value) => value.user);
      if (user == null) {
        return Left(FlowyError());
      }
      return Right(user.toUserProfile());
    } on AuthException catch (e) {
      Log.error(e);
      return Left(FlowyError());
    }
  }

  Future<Either<FlowyError, UserProfilePB>> signInWithOAuth({
    Provider provider = Provider.github,
  }) async {
    final response = await _auth.signInWithOAuth(provider);
    if (!response) {
      // TODO: handle error
      return left(FlowyError());
    }
    return getUser();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    final user = _auth.currentUser?.toUserProfile();
    if (user == null) {
      // TODO: handle error
      return left(FlowyError());
    }
    return Right(user);
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsAnonymousUser() {
    throw UnimplementedError();
  }
}

extension on User {
  UserProfilePB toUserProfile() {
    return UserProfilePB()
      ..email = email ?? ''
      ..token = this.id;
  }
}
