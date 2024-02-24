import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
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

    _dispatch();
  }

  final AuthService authService;
  void Function()? deepLinkStateListener;

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

  void _dispatch() {
    on<SignInEvent>(
      (event, emit) async {
        await event.map(
          signedInWithUserEmailAndPassword: (e) async {
            await _performActionOnSignIn(
              state,
              emit,
            );
          },
          signedInWithOAuth: (value) async =>
              _performActionOnSignInWithOAuth(state, emit, value.platform),
          signedInAsGuest: (value) async =>
              _performActionOnSignInAsGuest(state, emit),
          emailChanged: (EmailChanged value) async {
            emit(
              state.copyWith(
                email: value.email,
                emailError: null,
                successOrFail: null,
              ),
            );
          },
          passwordChanged: (PasswordChanged value) async {
            emit(
              state.copyWith(
                password: value.password,
                passwordError: null,
                successOrFail: null,
              ),
            );
          },
          signedWithMagicLink: (SignedWithMagicLink value) async {
            await _performActionOnSignInWithMagicLink(state, emit, value.email);
          },
          deepLinkStateChange: (_DeepLinkStateChange value) {
            final deepLinkState = value.result.state;

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
                if (value.result.result != null) {
                  emit(
                    value.result.result!.fold(
                      (userProfile) => state.copyWith(
                        isSubmitting: false,
                        successOrFail: FlowyResult.success(userProfile),
                      ),
                      (error) => stateFromCode(error),
                    ),
                  );
                }
            }
          },
          cancel: (value) {
            emit(
              state.copyWith(
                isSubmitting: false,
                emailError: null,
                passwordError: null,
                successOrFail: null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performActionOnSignIn(
    SignInState state,
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
        (error) => stateFromCode(error),
      ),
    );
  }

  Future<void> _performActionOnSignInWithOAuth(
    SignInState state,
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
        (error) => stateFromCode(error),
      ),
    );
  }

  Future<void> _performActionOnSignInWithMagicLink(
    SignInState state,
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
          isSubmitting: false,
          successOrFail: FlowyResult.success(userProfile),
        ),
        (error) => stateFromCode(error),
      ),
    );
  }

  Future<void> _performActionOnSignInAsGuest(
    SignInState state,
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
        (error) => stateFromCode(error),
      ),
    );
  }

  SignInState stateFromCode(FlowyError error) {
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
      _DeepLinkStateChange;
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
