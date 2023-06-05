import 'package:appflowy/user/application/auth_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final AuthService authService;
  SignInBloc(this.authService) : super(SignInState.initial()) {
    on<SignInEvent>((final event, final emit) async {
      await event.map(
        signedInWithUserEmailAndPassword: (final e) async {
          await _performActionOnSignIn(
            state,
            emit,
          );
        },
        emailChanged: (final EmailChanged value) async {
          emit(
            state.copyWith(
              email: value.email,
              emailError: none(),
              successOrFail: none(),
            ),
          );
        },
        passwordChanged: (final PasswordChanged value) async {
          emit(
            state.copyWith(
              password: value.password,
              passwordError: none(),
              successOrFail: none(),
            ),
          );
        },
      );
    });
  }

  Future<void> _performActionOnSignIn(
    final SignInState state,
    final Emitter<SignInState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: none(),
        passwordError: none(),
        successOrFail: none(),
      ),
    );

    final result = await authService.signIn(
      email: state.email,
      password: state.password,
    );
    emit(
      result.fold(
        (final userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(userProfile)),
        ),
        (final error) => stateFromCode(error),
      ),
    );
  }

  SignInState stateFromCode(final FlowyError error) {
    switch (ErrorCode.valueOf(error.code)!) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          emailError: some(error.msg),
          passwordError: none(),
        );
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          passwordError: some(error.msg),
          emailError: none(),
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
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signedInWithUserEmailAndPassword() =
      SignedInWithUserEmailAndPassword;
  const factory SignInEvent.emailChanged(final String email) = EmailChanged;
  const factory SignInEvent.passwordChanged(final String password) = PasswordChanged;
}

@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    final String? email,
    final String? password,
    required final bool isSubmitting,
    required final Option<String> passwordError,
    required final Option<String> emailError,
    required final Option<Either<UserProfilePB, FlowyError>> successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => SignInState(
        isSubmitting: false,
        passwordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
