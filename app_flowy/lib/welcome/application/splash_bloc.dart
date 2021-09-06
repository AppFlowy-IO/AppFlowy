import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_welcome.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_bloc.freezed.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final ISplashAuth authImpl;
  SplashBloc(this.authImpl) : super(SplashState.initial());

  @override
  Stream<SplashState> mapEventToState(SplashEvent event) async* {
    yield* event.map(
      getUser: (val) async* {
        final authState = await authImpl.currentUserProfile();
        yield state.copyWith(auth: authState);
      },
    );
  }
}

@freezed
abstract class SplashEvent with _$SplashEvent {
  const factory SplashEvent.getUser() = _GetUser;
}

@freezed
abstract class SplashState implements _$SplashState {
  const factory SplashState({
    required AuthState auth,
  }) = _SplashState;

  factory SplashState.initial() => const SplashState(
        auth: AuthState.initial(),
      );
}
