import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_bloc.freezed.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this.authService) : super(SignUpState.initial()) {
    _dispatch();
  }

  final AuthService authService;

  void _dispatch() {
    on<SignUpEvent>(
      (event, emit) async {
        await event.map(
          signUpWithUserEmailAndPassword: (e) async {
            await _performActionOnSignUp(emit);
          },
          emailChanged: (_EmailChanged value) async {
            emit(
              state.copyWith(
                email: value.email,
                emailError: null,
                successOrFail: null,
              ),
            );
          },
          passwordChanged: (_PasswordChanged value) async {
            emit(
              state.copyWith(
                password: value.password,
                passwordError: null,
                successOrFail: null,
              ),
            );
          },
          repeatPasswordChanged: (_RepeatPasswordChanged value) async {
            emit(
              state.copyWith(
                repeatedPassword: value.password,
                repeatPasswordError: null,
                successOrFail: null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performActionOnSignUp(Emitter<SignUpState> emit) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        successOrFail: null,
      ),
    );

    final password = state.password;
    final repeatedPassword = state.repeatedPassword;
    if (password == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          passwordError: LocaleKeys.signUp_emptyPasswordError.tr(),
        ),
      );
      return;
    }

    if (repeatedPassword == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          repeatPasswordError: LocaleKeys.signUp_repeatPasswordEmptyError.tr(),
        ),
      );
      return;
    }

    if (password != repeatedPassword) {
      emit(
        state.copyWith(
          isSubmitting: false,
          repeatPasswordError: LocaleKeys.signUp_unmatchedPasswordError.tr(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        passwordError: null,
        repeatPasswordError: null,
      ),
    );

    final result = await authService.signUp(
      name: state.email ?? '',
      password: state.password ?? '',
      email: state.email ?? '',
    );
    emit(
      result.fold(
        (profile) => state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.success(profile),
          emailError: null,
          passwordError: null,
          repeatPasswordError: null,
        ),
        (error) => stateFromCode(error),
      ),
    );
  }

  SignUpState stateFromCode(FlowyError error) {
    switch (error.code) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          emailError: error.msg,
          passwordError: null,
          successOrFail: null,
        );
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          passwordError: error.msg,
          emailError: null,
          successOrFail: null,
        );
      default:
        return state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.failure(error),
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
    required String? passwordError,
    required String? repeatPasswordError,
    required String? emailError,
    required FlowyResult<UserProfilePB, FlowyError>? successOrFail,
  }) = _SignUpState;

  factory SignUpState.initial() => const SignUpState(
        isSubmitting: false,
        passwordError: null,
        repeatPasswordError: null,
        emailError: null,
        successOrFail: null,
      );
}
