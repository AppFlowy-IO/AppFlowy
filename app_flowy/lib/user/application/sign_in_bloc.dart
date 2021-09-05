import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final IAuth authImpl;
  SignInBloc(this.authImpl) : super(SignInState.initial());

  @override
  Stream<SignInState> mapEventToState(
    SignInEvent event,
  ) async* {
    yield* event.map(
      signedInWithUserEmailAndPassword: (e) async* {
        yield* _performActionOnSignIn(
          state,
        );
      },
      emailChanged: (EmailChanged value) async* {
        yield state.copyWith(email: value.email, successOrFail: none());
      },
      passwordChanged: (PasswordChanged value) async* {
        yield state.copyWith(password: value.password, successOrFail: none());
      },
    );
  }

  Stream<SignInState> _performActionOnSignIn(SignInState state) async* {
    yield state.copyWith(isSubmitting: true);

    final result = await authImpl.signIn(state.email, state.password);
    yield result.fold(
      (userProfile) => state.copyWith(
          isSubmitting: false, successOrFail: some(left(userProfile))),
      (error) => stateFromCode(error),
    );
  }

  SignInState stateFromCode(UserError error) {
    switch (error.code) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(
            isSubmitting: false,
            emailError: some(error.msg),
            passwordError: none());
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(
            isSubmitting: false,
            passwordError: some(error.msg),
            emailError: none());
      default:
        return state.copyWith(
            isSubmitting: false, successOrFail: some(right(error)));
    }
  }
}

@freezed
abstract class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signedInWithUserEmailAndPassword() =
      SignedInWithUserEmailAndPassword;
  const factory SignInEvent.emailChanged(String email) = EmailChanged;
  const factory SignInEvent.passwordChanged(String password) = PasswordChanged;
}

@freezed
abstract class SignInState with _$SignInState {
  const factory SignInState({
    String? email,
    String? password,
    required bool isSubmitting,
    required Option<String> passwordError,
    required Option<String> emailError,
    required Option<Either<UserProfile, UserError>> successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => SignInState(
        isSubmitting: false,
        passwordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
