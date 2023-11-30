import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
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

  SignInBloc(this.authService) : super(SignInState.initial()) {
    if (isAppFlowyCloudEnabled) {
      deepLinkStateListener =
          getIt<AppFlowyCloudDeepLink>().subscribeDeepLinkLoadingState((value) {
        if (isClosed) return;

        add(SignInEvent.deepLinkStateChange(value));
      });
    }

    on<SignInEvent>((event, emit) async {
      await event.map(
        signedInWithUserEmailAndPassword: (e) async {
          await _performActionOnSignIn(
            state,
            emit,
          );
        },
        signedInWithOAuth: (value) async =>
            await _performActionOnSignInWithOAuth(
          state,
          emit,
          value.platform,
        ),
        signedInAsGuest: (value) async => await _performActionOnSignInAsGuest(
          state,
          emit,
        ),
        emailChanged: (EmailChanged value) async {
          emit(
            state.copyWith(
              email: value.email,
              emailError: none(),
              successOrFail: none(),
            ),
          );
        },
        passwordChanged: (PasswordChanged value) async {
          emit(
            state.copyWith(
              password: value.password,
              passwordError: none(),
              successOrFail: none(),
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
                  emailError: none(),
                  passwordError: none(),
                  successOrFail: none(),
                ),
              );
            case DeepLinkState.finish:
              if (value.result.result != null) {
                emit(
                  value.result.result!.fold(
                    (error) => stateFromCode(error),
                    (userProfile) => state.copyWith(
                      isSubmitting: false,
                      successOrFail: some(left(userProfile)),
                    ),
                  ),
                );
              }
          }
        },
      );
    });
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
        (error) => stateFromCode(error),
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(userProfile)),
        ),
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
        emailError: none(),
        passwordError: none(),
        successOrFail: none(),
      ),
    );

    final result = await authService.signUpWithOAuth(
      platform: platform,
    );
    emit(
      result.fold(
        (error) => stateFromCode(error),
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(userProfile)),
        ),
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
        emailError: none(),
        passwordError: none(),
        successOrFail: none(),
      ),
    );

    final result = await authService.signInWithMagicLink(
      email: email,
    );
    emit(
      result.fold(
        (error) => stateFromCode(error),
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(userProfile)),
        ),
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
        emailError: none(),
        passwordError: none(),
        successOrFail: none(),
      ),
    );

    final result = await authService.signUpAsGuest();
    emit(
      result.fold(
        (error) => stateFromCode(error),
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: some(left(userProfile)),
        ),
      ),
    );
  }

  SignInState stateFromCode(FlowyError error) {
    switch (error.code) {
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
  const factory SignInEvent.signedInWithOAuth(String platform) =
      SignedInWithOAuth;
  const factory SignInEvent.signedInAsGuest() = SignedInAsGuest;
  const factory SignInEvent.signedWithMagicLink(String email) =
      SignedWithMagicLink;
  const factory SignInEvent.emailChanged(String email) = EmailChanged;
  const factory SignInEvent.passwordChanged(String password) = PasswordChanged;
  const factory SignInEvent.deepLinkStateChange(DeepLinkResult result) =
      _DeepLinkStateChange;
}

@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    String? email,
    String? password,
    required bool isSubmitting,
    required Option<String> passwordError,
    required Option<String> emailError,
    required Option<Either<UserProfilePB, FlowyError>> successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => SignInState(
        isSubmitting: false,
        passwordError: none(),
        emailError: none(),
        successOrFail: none(),
      );
}
