import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth/auth_service.dart';

part 'encrypt_secret_bloc.freezed.dart';

class EncryptSecretBloc extends Bloc<EncryptSecretEvent, EncryptSecretState> {
  EncryptSecretBloc({required this.user})
      : super(EncryptSecretState.initial()) {
    _dispatch();
  }

  final UserProfilePB user;

  void _dispatch() {
    on<EncryptSecretEvent>((event, emit) async {
      await event.when(
        setEncryptSecret: (secret) async {
          if (isLoading()) {
            return;
          }

          final payload = UserSecretPB.create()
            ..encryptionSecret = secret
            ..encryptionSign = user.encryptionSign
            ..encryptionType = user.encryptionType
            ..userId = user.id;
          final result = await UserEventSetEncryptionSecret(payload).send();
          if (!isClosed) {
            add(EncryptSecretEvent.didFinishCheck(result));
          }
          emit(
            state.copyWith(
              loadingState: const LoadingState.loading(),
              successOrFail: null,
            ),
          );
        },
        cancelInputSecret: () async {
          await getIt<AuthService>().signOut();
          emit(
            state.copyWith(
              successOrFail: null,
              isSignOut: true,
            ),
          );
        },
        didFinishCheck: (result) {
          result.fold(
            (unit) {
              emit(
                state.copyWith(
                  loadingState: const LoadingState.loading(),
                  successOrFail: result,
                ),
              );
            },
            (err) {
              emit(
                state.copyWith(
                  loadingState: LoadingState.finish(FlowyResult.failure(err)),
                  successOrFail: result,
                ),
              );
            },
          );
        },
      );
    });
  }

  bool isLoading() {
    final loadingState = state.loadingState;
    if (loadingState != null) {
      return loadingState.when(
        loading: () => true,
        finish: (_) => false,
        idle: () => false,
      );
    }
    return false;
  }
}

@freezed
class EncryptSecretEvent with _$EncryptSecretEvent {
  const factory EncryptSecretEvent.setEncryptSecret(String secret) =
      _SetEncryptSecret;
  const factory EncryptSecretEvent.didFinishCheck(
    FlowyResult<void, FlowyError> result,
  ) = _DidFinishCheck;
  const factory EncryptSecretEvent.cancelInputSecret() = _CancelInputSecret;
}

@freezed
class EncryptSecretState with _$EncryptSecretState {
  const factory EncryptSecretState({
    required FlowyResult<void, FlowyError>? successOrFail,
    required bool isSignOut,
    LoadingState? loadingState,
  }) = _EncryptSecretState;

  factory EncryptSecretState.initial() => const EncryptSecretState(
        successOrFail: null,
        isSignOut: false,
      );
}
