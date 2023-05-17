import 'dart:async';

import 'package:appflowy/user/application/supabase_auth_service.dart';
import 'package:appflowy/user/domain/auth_state.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_bloc.freezed.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashState.initial()) {
    on<SplashEvent>((event, emit) async {
      await event.map(
        getUser: (val) async {
          // await getUserFromLocalService(emit);
          await getUserFromSupabase(emit);
        },
      );
    });
  }

  Future<void> getUserFromLocalService(Emitter<SplashState> emit) async {
    final result = await UserEventCheckUser().send();
    final authState = result.fold(
      (userProfile) => AuthState.authenticated(userProfile),
      (error) => AuthState.unauthenticated(error),
    );

    emit(state.copyWith(auth: authState));
  }

  // move the function to a single file
  final _supabaseAuth = const SupabaseAuthService();
  Future<void> getUserFromSupabase(Emitter<SplashState> emit) async {
    const email = '';
    const password = '';
    assert(email.isNotEmpty && password.isNotEmpty);
    final response = await _supabaseAuth.signIn(email, password);
    // TODO: redefine the user profile pb, make id as String.
    final auth = response.fold(
      (l) => AuthState.unauthenticated(FlowyError()),
      (r) => AuthState.authenticated(UserProfilePB()..email = r.email!),
    );
    emit(state.copyWith(auth: auth));
  }
}

@freezed
class SplashEvent with _$SplashEvent {
  const factory SplashEvent.getUser() = _GetUser;
}

@freezed
class SplashState with _$SplashState {
  const factory SplashState({
    required AuthState auth,
  }) = _SplashState;

  factory SplashState.initial() => const SplashState(
        auth: AuthState.initial(),
      );
}
