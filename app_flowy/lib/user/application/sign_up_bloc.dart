import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_up_bloc.freezed.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final IAuth authImpl;
  SignUpBloc(this.authImpl) : super(SignUpState.initial());

  @override
  Stream<SignUpState> mapEventToState(
    SignUpEvent event,
  ) async* {
    yield* event.map(
      signUpWithUserEmailAndPassword: (e) async* {
        yield* _performActionOnSignUp(
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

  Stream<SignUpState> _performActionOnSignUp(SignUpState state) async* {
    yield state.copyWith(isSubmitting: true);

    final result = await authImpl.signIn(state.email, state.password);
    yield result.fold(
      (userProfile) => state.copyWith(
          isSubmitting: false, successOrFail: some(left(userProfile))),
      (error) => stateFromCode(error),
    );
  }

  SignUpState stateFromCode(UserError error) {
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
abstract class SignUpEvent with _$SignUpEvent {
  const factory SignUpEvent.signUpWithUserEmailAndPassword() =
      SignUpWithUserEmailAndPassword;
  const factory SignUpEvent.emailChanged(String email) = EmailChanged;
  const factory SignUpEvent.passwordChanged(String password) = PasswordChanged;
}

@freezed
abstract class SignUpState with _$SignUpState {
  const factory SignUpState({
    String? email,
    String? password,
    required bool isSubmitting,
    required Option<String> passwordError,
    required Option<String> emailError,
    required Option<Either<UserProfile, UserError>> successOrFail,
  }) = _SignUpState;

  factory SignUpState.initial() => SignUpState(
        isSubmitting: false,
        passwordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
