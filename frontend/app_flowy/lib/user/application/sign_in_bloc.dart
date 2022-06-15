import 'package:app_flowy/user/application/auth_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error-code/code.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final AuthService authService;
  SignInBloc(this.authService) : super(SignInState.initial()) {
    on<SignInEvent>((event, emit) async {
      await event.map(
        signedInWithUserEmailAndPassword: (e) async {
          await _performActionOnSignIn(
            state,
            emit,
          );
        },
        emailChanged: (EmailChanged value) async {
          emit(state.copyWith(email: value.email, emailError: none(), successOrFail: none()));
        },
        passwordChanged: (PasswordChanged value) async {
          emit(state.copyWith(password: value.password, passwordError: none(), successOrFail: none()));
        },
      );
    });
  }

  Future<void> _performActionOnSignIn(SignInState state, Emitter<SignInState> emit) async {
    emit(state.copyWith(isSubmitting: true, emailError: none(), passwordError: none(), successOrFail: none()));

    final result = await authService.signIn(
      email: state.email,
      password: state.password,
    );
    emit(result.fold(
      (userProfile) => state.copyWith(isSubmitting: false, successOrFail: some(left(userProfile))),
      (error) => stateFromCode(error),
    ));
  }

  SignInState stateFromCode(FlowyError error) {
    switch (ErrorCode.valueOf(error.code)!) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(isSubmitting: false, emailError: some(error.msg), passwordError: none());
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(isSubmitting: false, passwordError: some(error.msg), emailError: none());
      default:
        return state.copyWith(isSubmitting: false, successOrFail: some(right(error)));
    }
  }
}

@freezed
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signedInWithUserEmailAndPassword() = SignedInWithUserEmailAndPassword;
  const factory SignInEvent.emailChanged(String email) = EmailChanged;
  const factory SignInEvent.passwordChanged(String password) = PasswordChanged;
}

@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    String? email,
    String? password,
    required bool isSubmitting,
    required Option<String> passwordError,
    required Option<String> emailError,
    required Option<Either<UserProfile, FlowyError>> successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => SignInState(
        isSubmitting: false,
        passwordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
