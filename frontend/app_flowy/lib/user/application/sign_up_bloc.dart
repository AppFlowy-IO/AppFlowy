import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile, ErrorCode;
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_up_bloc.freezed.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final IAuth authManager;
  SignUpBloc(this.authManager) : super(SignUpState.initial());

  @override
  Stream<SignUpState> mapEventToState(
    SignUpEvent event,
  ) async* {
    yield* event.map(signUpWithUserEmailAndPassword: (e) async* {
      yield* _performActionOnSignUp();
    }, emailChanged: (EmailChanged value) async* {
      yield state.copyWith(email: value.email, emailError: none(), successOrFail: none());
    }, passwordChanged: (PasswordChanged value) async* {
      yield state.copyWith(password: value.password, passwordError: none(), successOrFail: none());
    }, repeatPasswordChanged: (RepeatPasswordChanged value) async* {
      yield state.copyWith(repeatedPassword: value.password, repeatPasswordError: none(), successOrFail: none());
    });
  }

  Stream<SignUpState> _performActionOnSignUp() async* {
    yield state.copyWith(
      isSubmitting: true,
      successOrFail: none(),
    );

    final password = state.password;
    final repeatedPassword = state.repeatedPassword;
    if (password == null) {
      yield state.copyWith(
        isSubmitting: false,
        passwordError: some("Password can't be empty"),
      );
      return;
    }

    if (repeatedPassword == null) {
      yield state.copyWith(
        isSubmitting: false,
        repeatPasswordError: some("Repeat password can't be empty"),
      );
      return;
    }

    if (password != repeatedPassword) {
      yield state.copyWith(
        isSubmitting: false,
        repeatPasswordError: some("Repeat password is not the same as password"),
      );
      return;
    }

    yield state.copyWith(
      passwordError: none(),
      repeatPasswordError: none(),
    );

    final result = await authManager.signUp(state.email, state.password, state.email);
    yield result.fold(
      (profile) => state.copyWith(
        isSubmitting: false,
        successOrFail: some(left(profile)),
        emailError: none(),
        passwordError: none(),
        repeatPasswordError: none(),
      ),
      (error) => stateFromCode(error),
    );
  }

  SignUpState stateFromCode(UserError error) {
    switch (ErrorCode.valueOf(error.code)!) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          emailError: some(error.msg),
          passwordError: none(),
          successOrFail: none(),
        );
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          passwordError: some(error.msg),
          emailError: none(),
          successOrFail: none(),
        );
      default:
        return state.copyWith(isSubmitting: false, successOrFail: some(right(error)));
    }
  }
}

@freezed
class SignUpEvent with _$SignUpEvent {
  const factory SignUpEvent.signUpWithUserEmailAndPassword() = SignUpWithUserEmailAndPassword;
  const factory SignUpEvent.emailChanged(String email) = EmailChanged;
  const factory SignUpEvent.passwordChanged(String password) = PasswordChanged;
  const factory SignUpEvent.repeatPasswordChanged(String password) = RepeatPasswordChanged;
}

@freezed
class SignUpState with _$SignUpState {
  const factory SignUpState({
    String? email,
    String? password,
    String? repeatedPassword,
    required bool isSubmitting,
    required Option<String> passwordError,
    required Option<String> repeatPasswordError,
    required Option<String> emailError,
    required Option<Either<UserProfile, UserError>> successOrFail,
  }) = _SignUpState;

  factory SignUpState.initial() => SignUpState(
        isSubmitting: false,
        passwordError: none(),
        repeatPasswordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
