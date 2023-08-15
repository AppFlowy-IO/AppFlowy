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
          final payload = UserSecretPB.create()
            ..encryptionSecret = secret
            ..encryptionSign = user.encryptionSign
            ..encryptionTy = user.encryptionTy
            ..userId = user.id;
          UserEventSetEncryptionSecret(payload).send().then((result) {
            if (!isClosed) {
              add(EncryptSecretEvent.didFinishCheck(result, true));
            }
          });
        },
        cancelInputSecret: () async {
          await getIt<AuthService>().signOut();
          emit(
            state.copyWith(
              isSignOut: true,
            ),
          );
        },
        didFinishCheck: (Either<Unit, FlowyError> result, bool isChecked) {
          emit(
            state.copyWith(
              successOrFail: result,
              isChecked: isChecked,
            ),
          );
        },
      );
    });
  }
}

@freezed
class EncryptSecretEvent with _$EncryptSecretEvent {
  const factory EncryptSecretEvent.setEncryptSecret(String secret) =
      _SetEncryptSecret;
  const factory EncryptSecretEvent.didFinishCheck(
    Either<Unit, FlowyError> result,
    bool isChecked,
  ) = _DidFinishCheck;
  const factory EncryptSecretEvent.cancelInputSecret() = _CancelInputSecret;
}

@freezed
class EncryptSecretState with _$EncryptSecretState {
  const factory EncryptSecretState({
    required Either<Unit, FlowyError> successOrFail,
    required bool isSignOut,
    required bool isChecked,
  }) = _EncryptSecretState;

  factory EncryptSecretState.initial() => EncryptSecretState(
        successOrFail: left(unit),
        isSignOut: false,
        isChecked: false,
      );
}
