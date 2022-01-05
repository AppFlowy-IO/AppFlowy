import 'package:app_flowy/user/domain/auth_state.dart';
import 'package:app_flowy/user/domain/i_splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_bloc.freezed.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final ISplashUser authImpl;
  SplashBloc(this.authImpl) : super(SplashState.initial()) {
    on<SplashEvent>((event, emit) async {
      await event.map(
        getUser: (val) async {
          final authState = await authImpl.currentUserProfile();
          emit(state.copyWith(auth: authState));
        },
      );
    });
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
