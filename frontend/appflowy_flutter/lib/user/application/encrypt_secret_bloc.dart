import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth/auth_service.dart';

part 'encrypt_secret_bloc.freezed.dart';

class EncryptSecretBloc extends Bloc<EncryptSecretEvent, EncryptSecretState> {
  final UserProfilePB user;
  EncryptSecretBloc({required this.user})
      : super(EncryptSecretState.initial()) {
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
          UserEventSetEncryptionSecret(payload).send().then((result) {
            if (!isClosed) {
              add(EncryptSecretEvent.didFinishCheck(result));
            }
          });
          emit(
            state.copyWith(
              loadingState: const LoadingState.loading(),
              successOrFail: none(),
            ),
          );
        },
        cancelInputSecret: () async {
          await getIt<AuthService>().signOut();
          emit(
            state.copyWith(
              successOrFail: none(),
              isSignOut: true,
            ),
          );
        },
        didFinishCheck: (Either<Unit, FlowyError> result) {
          result.fold(
            (unit) {
              emit(
                state.copyWith(
                  loadingState: const LoadingState.loading(),
                  successOrFail: Some(result),
                ),
              );
            },
            (err) {
              emit(
                state.copyWith(
                  loadingState: LoadingState.finish(right(err)),
                  successOrFail: Some(result),
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
      return loadingState.when(loading: () => true, finish: (_) => false);
    }
    return false;
  }
}

@freezed
class EncryptSecretEvent with _$EncryptSecretEvent {
  const factory EncryptSecretEvent.setEncryptSecret(String secret) =
      _SetEncryptSecret;
  const factory EncryptSecretEvent.didFinishCheck(
    Either<Unit, FlowyError> result,
  ) = _DidFinishCheck;
  const factory EncryptSecretEvent.cancelInputSecret() = _CancelInputSecret;
}

@freezed
class EncryptSecretState with _$EncryptSecretState {
  const factory EncryptSecretState({
    required Option<Either<Unit, FlowyError>> successOrFail,
    required bool isSignOut,
    LoadingState? loadingState,
  }) = _EncryptSecretState;

  factory EncryptSecretState.initial() => EncryptSecretState(
        successOrFail: none(),
        isSignOut: false,
      );
}
