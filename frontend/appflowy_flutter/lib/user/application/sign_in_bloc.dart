import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
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
          signInWithEmailAndPassword: (email, password) async =>
              _onSignInWithEmailAndPassword(
            emit,
            email: email,
            password: password,
          ),
          signInWithOAuth: (platform) async => _onSignInWithOAuth(
            emit,
            platform: platform,
          ),
          signInAsGuest: () async => _onSignInAsGuest(emit),
          signInWithMagicLink: (email) async => _onSignInWithMagicLink(
            emit,
            email: email,
          ),
          signInWithPasscode: (email, passcode) async => _onSignInWithPasscode(
            emit,
            email: email,
            passcode: passcode,
          ),
          deepLinkStateChange: (result) => _onDeepLinkStateChange(emit, result),
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
          switchLoginType: (type) {
            emit(state.copyWith(loginType: type));
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

  Future<void> _onSignInWithEmailAndPassword(
    Emitter<SignInState> emit, {
    required String email,
    required String password,
  }) async {
    final result = await authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    emit(
      result.fold(
        (gotrueTokenResponse) {
          getIt<AppFlowyCloudDeepLink>().passGotrueTokenResponse(
            gotrueTokenResponse,
          );
          return state.copyWith(
            isSubmitting: false,
          );
        },
        (error) => _stateFromCode(error),
      ),
    );
  }

  Future<void> _onSignInWithOAuth(
    Emitter<SignInState> emit, {
    required String platform,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signUpWithOAuth(platform: platform);
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
    Emitter<SignInState> emit, {
    required String email,
  }) async {
    if (state.isSubmitting) {
      Log.error('Sign in with magic link is already in progress');
      return;
    }

    Log.info('Sign in with magic link: $email');

    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signInWithMagicLink(email: email);

    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: false,
        ),
        (error) => _stateFromCode(error),
      ),
    );
  }

  Future<void> _onSignInWithPasscode(
    Emitter<SignInState> emit, {
    required String email,
    required String passcode,
  }) async {
    if (state.isSubmitting) {
      Log.error('Sign in with passcode is already in progress');
      return;
    }

    Log.info('Sign in with passcode: $email, $passcode');

    emit(
      state.copyWith(
        isSubmitting: true,
        emailError: null,
        passwordError: null,
        successOrFail: null,
      ),
    );

    final result = await authService.signInWithPasscode(
      email: email,
      passcode: passcode,
    );

    emit(
      result.fold(
        (gotrueTokenResponse) {
          getIt<AppFlowyCloudDeepLink>().passGotrueTokenResponse(
            gotrueTokenResponse,
          );
          return state.copyWith(
            isSubmitting: false,
          );
        },
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
    Log.error('SignInState _stateFromCode: ${error.msg}');

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
      case ErrorCode.UserUnauthorized:
        final errorMsg = error.msg;
        String msg = LocaleKeys.signIn_generalError.tr();
        if (errorMsg.contains('rate limit') ||
            errorMsg.contains('For security purposes')) {
          msg = LocaleKeys.signIn_tooFrequentVerificationCodeRequest.tr();
        } else if (errorMsg.contains('invalid')) {
          msg = LocaleKeys.signIn_tokenHasExpiredOrInvalid.tr();
        } else if (errorMsg.contains('Invalid login credentials')) {
          msg = LocaleKeys.signIn_invalidLoginCredentials.tr();
        }
        return state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.failure(
            FlowyError(msg: msg),
          ),
        );
      default:
        return state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.failure(
            FlowyError(msg: LocaleKeys.signIn_generalError.tr()),
          ),
        );
    }
  }
}

@freezed
class SignInEvent with _$SignInEvent {
  // Sign in methods
  const factory SignInEvent.signInWithEmailAndPassword({
    required String email,
    required String password,
  }) = SignInWithEmailAndPassword;
  const factory SignInEvent.signInWithOAuth({
    required String platform,
  }) = SignInWithOAuth;
  const factory SignInEvent.signInAsGuest() = SignInAsGuest;
  const factory SignInEvent.signInWithMagicLink({
    required String email,
  }) = SignInWithMagicLink;
  const factory SignInEvent.signInWithPasscode({
    required String email,
    required String passcode,
  }) = SignInWithPasscode;

  // Event handlers
  const factory SignInEvent.emailChanged({
    required String email,
  }) = EmailChanged;
  const factory SignInEvent.passwordChanged({
    required String password,
  }) = PasswordChanged;
  const factory SignInEvent.deepLinkStateChange(DeepLinkResult result) =
      DeepLinkStateChange;

  const factory SignInEvent.cancel() = Cancel;
  const factory SignInEvent.switchLoginType(LoginType type) = SwitchLoginType;
}

// we support sign in directly without sign up, but we want to allow the users to sign up if they want to
// this type is only for the UI to know which form to show
enum LoginType {
  signIn,
  signUp,
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
    @Default(LoginType.signIn) LoginType loginType,
  }) = _SignInState;

  factory SignInState.initial() => const SignInState(
        isSubmitting: false,
        passwordError: null,
        emailError: null,
        successOrFail: null,
      );
}
