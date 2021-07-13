part of 'sign_in_bloc.dart';

@freezed
abstract class SignInState with _$SignInState {
  const factory SignInState({
    String? email,
    String? password,
    required bool isSubmitting,
    required Option<Either<UserDetail, UserError>> signInFailure,
  }) = _SignInState;

  factory SignInState.initial() => SignInState(
        isSubmitting: false,
        signInFailure: none(),
      );
}
