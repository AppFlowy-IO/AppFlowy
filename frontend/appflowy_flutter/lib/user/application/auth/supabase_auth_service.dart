import 'dart:async';

import 'package:appflowy/user/application/auth/appflowy_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart'
    show AuthTypePB;
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_error.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService();

  SupabaseClient get _client => Supabase.instance.client;
  GoTrueClient get _auth => _client.auth;

  final AppFlowyAuthService _appFlowyAuthService = AppFlowyAuthService();

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    AuthTypePB authType = AuthTypePB.Supabase,
    Map<String, String> map = const {},
  }) async {
    // fetch the uuid from supabase.
    final response = await _auth.signUp(
      email: email,
      password: password,
    );
    final uuid = response.user?.id;
    if (uuid == null) {
      return left(AuthError.supabaseSignUpError);
    }
    // assign the uuid to our backend service.
    //  and will transfer this logic to backend later.
    return _appFlowyAuthService.signUp(
      name: name,
      email: email,
      password: password,
      authType: authType,
      map: {
        AuthServiceMapKeys.uuid: uuid,
      },
    );
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    AuthTypePB authType = AuthTypePB.Supabase,
    Map<String, String> map = const {},
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final uuid = response.user?.id;
      if (uuid == null) {
        return Left(AuthError.supabaseSignInError);
      }
      return _appFlowyAuthService.signIn(
        email: email,
        password: password,
        authType: authType,
        map: {
          AuthServiceMapKeys.uuid: uuid,
        },
      );
    } on AuthException catch (e) {
      Log.error(e);
      return Left(AuthError.supabaseSignInError);
    }
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType = AuthTypePB.Supabase,
    Map<String, String> map = const {},
  }) async {
    final provider = platform.toProvider();
    final completer = Completer<Either<FlowyError, UserProfilePB>>();
    late final StreamSubscription<AuthState> subscription;
    subscription = _auth.onAuthStateChange.listen((event) async {
      if (event.event != AuthChangeEvent.signedIn) {
        completer.complete(left(AuthError.supabaseSignInWithOauthError));
      } else {
        final user = await getSupabaseUser();
        final Either<FlowyError, UserProfilePB> response = await user.fold(
          (l) => left(l),
          (r) async => await _appFlowyAuthService.signUp(
            name: r.email ?? '',
            email: r.email ?? '',
            password: 'AppFlowy123..',
            authType: authType,
            map: {
              AuthServiceMapKeys.uuid: r.id,
            },
          ),
        );
        completer.complete(response);
      }
      subscription.cancel();
    });
    final Map<String, String> query = {};
    if (provider == Provider.google) {
      query['access_type'] = 'offline';
      query['prompt'] = 'consent';
    }
    final response = await _auth.signInWithOAuth(
      provider,
      queryParams: query,
      redirectTo:
          'io.appflowy.appflowy-flutter://login-callback', // can't use underscore here.
    );
    if (!response) {
      completer.complete(left(AuthError.supabaseSignInWithOauthError));
    }
    return completer.future;
  }

  @override
  Future<void> signOut({
    AuthTypePB authType = AuthTypePB.Local,
  }) async {
    await _auth.signOut();
    await _appFlowyAuthService.signOut(
      authType: authType,
    );
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsAnonymousUser({
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    final user = await getSupabaseUser();
    return user.map((r) => r.toUserProfile());
  }

  Future<Either<FlowyError, User>> getSupabaseUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return left(AuthError.supabaseGetUserError);
    }
    return Right(user);
  }
}

extension on User {
  UserProfilePB toUserProfile() {
    return UserProfilePB()
      ..email = email ?? ''
      ..token = this.id;
  }
}

extension on String {
  Provider toProvider() {
    switch (this) {
      case 'github':
        return Provider.github;
      case 'google':
        return Provider.google;
      case 'discord':
        return Provider.discord;
      default:
        throw UnimplementedError();
    }
  }
}
