import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this.authService) : super(SignInState.initial()) {
    if (isAppFlowyCloudEnabled) {
      deepLinkStateListener =
          getIt<AppFlowyCloudDeepLink>().subscribeDeepLinkLoadingState((value) {
        if (isClosed) return;

        add(SignInEvent.deepLinkStateChange(value));
      });
    }

    on<SignInEvent>(
      (event, emit) async {
        await event.when(
          signedInWithUserEmailAndPassword: () async => _onSignIn(emit),
          signedInWithOAuth: (platform) async => _onSignInWithOAuth(
            emit,
            platform,
          ),
          signedInAsGuest: () async => _onSignInAsGuest(emit),
          signedWithMagicLink: (email) async => _onSignInWithMagicLink(
            emit,
            email,
          ),
          deepLinkStateChange: (result) => _onDeepLinkStateChange(
            emit,
            result,
          ),
          cancel: () {
            emit(
              state.copyWith(
                isSubmitting: false,
                emailError: null,
                passwordError: null,
                successOrFail: null,
              ),
            );
          },
          emailChanged: (email) async {
            emit(
              state.copyWith(
                email: email,
                emailError: null,
                successOrFail: null,
              ),
            );
          },
          passwordChanged: (password) async {
            emit(
              state.copyWith(
                password: password,
                passwordError: null,
                successOrFail: null,
              ),
            );
          },
        );
      },
    );
  }

  final AuthService authService;
  VoidCallback? deepLinkStateListener;

  @override
  Future<void> close() {
    deepLinkStateListener?.call();
    if (isAppFlowyCloudEnabled && deepLinkStateListener != null) {
      getIt<AppFlowyCloudDeepLink>().unsubscribeDeepLinkLoadingState(
        deepLinkStateListener!,
      );
    }
    return super.close();
  }

  Future<void> _onDeepLinkStateChange(
    Emitter<SignInState> emit,
    DeepLinkResult result,
  ) async {
    final deepLinkState = result.state;

    switch (deepLinkState) {
      case DeepLinkState.none:
        break;
      case DeepLinkState.loading:
        emit(
          state.copyWith(
            isSubmitting: true,
            emailError: null,
            passwordError: null,
            successOrFail: null,
          ),
        );
      case DeepLinkState.finish:
        final newState = result.result?.fold(
          (s) => state.copyWith(
            isSubmitting: false,
            successOrFail: FlowyResult.success(s),
          ),
          (f) => _stateFromCode(f),
        );
        if (newState != null) {
          emit(newState);
        }
    }
  }

  Future<void> _onSignIn(
    Emitter<SignInState> emit,
  ) async {
    final result = await authService.signInWithEmailPassword(
      email: state.email ?? '',
      password: state.password ?? '',
    );
    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.success(userProfile),
        ),
        (error) => _stateFromCode(error),
      ),
    );
  }

  Future<void> _onSignInWithOAuth(
    Emitter<SignInState> emit,
    String platform,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signUpWithOAuth(
      platform: platform,
    );
    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.success(userProfile),
        ),
        (error) => _stateFromCode(error),
      ),
    );
  }

  Future<void> _onSignInWithMagicLink(
    Emitter<SignInState> emit,
    String email,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signInWithMagicLink(
      email: email,
    );

    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: true,
        ),
        (error) => _stateFromCode(error),
      ),
    );
  }

  Future<void> _onSignInAsGuest(
    Emitter<SignInState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signUpAsGuest();
    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.success(userProfile),
        ),
        (error) => _stateFromCode(error),
      ),
    );
  }

  SignInState _stateFromCode(FlowyError error) {
    switch (error.code) {
      case ErrorCode.EmailFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          emailError: error.msg,
          passwordError: null,
        );
      case ErrorCode.PasswordFormatInvalid:
        return state.copyWith(
          isSubmitting: false,
          passwordError: error.msg,
          emailError: null,
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
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signedInWithUserEmailAndPassword() =
      SignedInWithUserEmailAndPassword;
  const factory SignInEvent.signedInWithOAuth(String platform) =
      SignedInWithOAuth;
  const factory SignInEvent.signedInAsGuest() = SignedInAsGuest;
  const factory SignInEvent.signedWithMagicLink(String email) =
      SignedWithMagicLink;
  const factory SignInEvent.emailChanged(String email) = EmailChanged;
  const factory SignInEvent.passwordChanged(String password) = PasswordChanged;
  const factory SignInEvent.deepLinkStateChange(DeepLinkResult result) =
      DeepLinkStateChange;
  const factory SignInEvent.cancel() = _Cancel;
}

@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    String? email,
    String? password,
    required bool isSubmitting,
    required String? passwordError,
    required String? emailError,
    required FlowyResult<UserProfilePB, FlowyError>? successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => const SignInState(
        isSubmitting: false,
        passwordError: null,
        emailError: null,
        successOrFail: null,
      );
}
