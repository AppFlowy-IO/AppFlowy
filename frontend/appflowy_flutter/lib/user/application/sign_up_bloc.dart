import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

part 'sign_up_bloc.freezed.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final AuthService authService;
  SignUpBloc(this.authService) : super(SignUpState.initial()) {
    on<SignUpEvent>((event, emit) async {
      await event.map(
        signUpWithUserEmailAndPassword: (e) async {
          await _performActionOnSignUp(emit);
        },
        emailChanged: (_EmailChanged value) async {
          emit(
            state.copyWith(
              email: value.email,
              emailError: none(),
              successOrFail: none(),
            ),
          );
        },
        passwordChanged: (_PasswordChanged value) async {
          emit(
            state.copyWith(
              password: value.password,
              passwordError: none(),
              successOrFail: none(),
            ),
          );
        },
        repeatPasswordChanged: (_RepeatPasswordChanged value) async {
          emit(
            state.copyWith(
              repeatedPassword: value.password,
              repeatPasswordError: none(),
              successOrFail: none(),
            ),
          );
        },
      );
    });
  }

  Future<void> _performActionOnSignUp(Emitter<SignUpState> emit) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        successOrFail: none(),
      ),
    );

    final password = state.password;
    final repeatedPassword = state.repeatedPassword;
    if (password == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          passwordError: some(LocaleKeys.signUp_emptyPasswordError.tr()),
        ),
      );
      return;
    }

    if (repeatedPassword == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          repeatPasswordError:
              some(LocaleKeys.signUp_repeatPasswordEmptyError.tr()),
        ),
      );
      return;
    }

    if (password != repeatedPassword) {
      emit(
        state.copyWith(
          isSubmitting: false,
          repeatPasswordError:
              some(LocaleKeys.signUp_unmatchedPasswordError.tr()),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        passwordError: none(),
        repeatPasswordError: none(),
      ),
    );

    final result = await authService.signUp(
      name: state.email ?? '',
      password: state.password ?? '',
      email: state.email ?? '',
    );
    emit(
      result.fold(
        (error) => stateFromCode(error),
        (profile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(profile)),
          emailError: none(),
          passwordError: none(),
          repeatPasswordError: none(),
        ),
      ),
    );
  }

  SignUpState stateFromCode(FlowyError error) {
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
        return state.copyWith(
          isSubmitting: false,
          successOrFail: some(right(error)),
        );
    }
  }
}

@freezed
class SignUpEvent with _$SignUpEvent {
  const factory SignUpEvent.signUpWithUserEmailAndPassword() =
      SignUpWithUserEmailAndPassword;
  const factory SignUpEvent.emailChanged(String email) = _EmailChanged;
  const factory SignUpEvent.passwordChanged(String password) = _PasswordChanged;
  const factory SignUpEvent.repeatPasswordChanged(String password) =
      _RepeatPasswordChanged;
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
    required Option<Either<UserProfilePB, FlowyError>> successOrFail,
  }) = _SignUpState;

  factory SignUpState.initial() => SignUpState(
        isSubmitting: false,
        passwordError: none(),
        repeatPasswordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
