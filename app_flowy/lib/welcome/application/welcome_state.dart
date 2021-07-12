part of 'welcome_bloc.dart';

@freezed
abstract class WelcomeState implements _$WelcomeState {
  const factory WelcomeState({
    required AuthState auth,
  }) = _WelcomeState;

  factory WelcomeState.initial() => const WelcomeState(
        auth: AuthState.initial(),
      );
}
