import 'package:appflowy/user/application/auth_service.dart';
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
    on<SignUpEvent>((final event, final emit) async {
      await event.map(
        signUpWithUserEmailAndPassword: (final e) async {
          await _performActionOnSignUp(emit);
        },
        emailChanged: (final _EmailChanged value) async {
          emit(
            state.copyWith(
              email: value.email,
              emailError: none(),
              successOrFail: none(),
            ),
          );
        },
        passwordChanged: (final _PasswordChanged value) async {
          emit(
            state.copyWith(
              password: value.password,
              passwordError: none(),
              successOrFail: none(),
            ),
          );
        },
        repeatPasswordChanged: (final _RepeatPasswordChanged value) async {
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

  Future<void> _performActionOnSignUp(final Emitter<SignUpState> emit) async {
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
      name: state.email,
      password: state.password,
      email: state.email,
    );
    emit(
      result.fold(
        (final profile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(profile)),
          emailError: none(),
          passwordError: none(),
          repeatPasswordError: none(),
        ),
        (final error) => stateFromCode(error),
      ),
    );
  }

  SignUpState stateFromCode(final FlowyError error) {
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
  const factory SignUpEvent.emailChanged(final String email) = _EmailChanged;
  const factory SignUpEvent.passwordChanged(final String password) = _PasswordChanged;
  const factory SignUpEvent.repeatPasswordChanged(final String password) =
      _RepeatPasswordChanged;
}

@freezed
class SignUpState with _$SignUpState {
  const factory SignUpState({
    final String? email,
    final String? password,
    final String? repeatedPassword,
    required final bool isSubmitting,
    required final Option<String> passwordError,
    required final Option<String> repeatPasswordError,
    required final Option<String> emailError,
    required final Option<Either<UserProfilePB, FlowyError>> successOrFail,
  }) = _SignUpState;

  factory SignUpState.initial() => SignUpState(
        isSubmitting: false,
        passwordError: none(),
        repeatPasswordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
