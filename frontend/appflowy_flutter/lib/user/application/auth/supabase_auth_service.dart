import 'dart:async';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:appflowy/user/application/auth/appflowy_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
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
    if (!isSupabaseEnable) {
      return _appFlowyAuthService.signUp(
        name: name,
        email: email,
        password: password,
      );
    }

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
    if (!isSupabaseEnable) {
      return _appFlowyAuthService.signIn(
        email: email,
        password: password,
      );
    }

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
    if (!isSupabaseEnable) {
      return _appFlowyAuthService.signUpWithOAuth(
        platform: platform,
      );
    }
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
          (r) async => await setupAuth(map: {AuthServiceMapKeys.uuid: r.id}),
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
    AuthTypePB authType = AuthTypePB.Supabase,
  }) async {
    if (!isSupabaseEnable) {
      return _appFlowyAuthService.signOut();
    }
    await _auth.signOut();
    await _appFlowyAuthService.signOut(
      authType: authType,
    );
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    AuthTypePB authType = AuthTypePB.Supabase,
    Map<String, String> map = const {},
  }) async {
    // supabase don't support guest login.
    // so, just forward to our backend.
    return _appFlowyAuthService.signUpAsGuest();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    final loginType = await getIt<KeyValueStorage>()
        .get(KVKeys.loginType)
        .then((value) => value.toOption().toNullable());
    if (!isSupabaseEnable || (loginType != null && loginType != 'supabase')) {
      return _appFlowyAuthService.getUser();
    }
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

  Future<Either<FlowyError, UserProfilePB>> setupAuth({
    required Map<String, String> map,
  }) async {
    final payload = ThirdPartyAuthPB(
      authType: AuthTypePB.Supabase,
      map: map,
    );
    return UserEventThirdPartyAuth(payload)
        .send()
        .then((value) => value.swap());
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
