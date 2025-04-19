import 'dart:convert';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/user/application/password/password_http_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_bloc.freezed.dart';

class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  PasswordBloc(this.userProfile) : super(PasswordState.initial()) {
    on<PasswordEvent>(
      (event, emit) async {
        await event.when(
          init: () async => _init(),
          changePassword: (oldPassword, newPassword) async => _onChangePassword(
            emit,
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
          setupPassword: (newPassword) async => _onSetupPassword(
            emit,
            newPassword: newPassword,
          ),
          forgotPassword: (email) async => _onForgotPassword(
            emit,
            email: email,
          ),
          checkHasPassword: () async => _onCheckHasPassword(
            emit,
          ),
          cancel: () {},
        );
      },
    );
  }

  final UserProfilePB userProfile;
  late final PasswordHttpService passwordHttpService;

  bool _isInitialized = false;

  Future<void> _init() async {
    if (userProfile.authType == AuthenticatorPB.Local) {
      Log.debug('PasswordBloc: skip init because user is local authenticator');
      return;
    }

    final baseUrl = await getAppFlowyCloudUrl();
    try {
      final authToken = jsonDecode(userProfile.token)['access_token'];
      passwordHttpService = PasswordHttpService(
        baseUrl: baseUrl,
        authToken: authToken,
      );
      _isInitialized = true;
    } catch (e) {
      Log.error('PasswordBloc: _init: error: $e');
    }
  }

  Future<void> _onChangePassword(
    Emitter<PasswordState> emit, {
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!_isInitialized) {
      Log.info('changePassword: not initialized');
      return;
    }

    if (state.isSubmitting) {
      Log.info('changePassword: already submitting');
      return;
    }

    _clearState(emit, true);

    final result = await passwordHttpService.changePassword(
      currentPassword: oldPassword,
      newPassword: newPassword,
    );

    emit(
      state.copyWith(
        isSubmitting: false,
        changePasswordResult: result,
      ),
    );
  }

  Future<void> _onSetupPassword(
    Emitter<PasswordState> emit, {
    required String newPassword,
  }) async {
    if (!_isInitialized) {
      Log.info('setupPassword: not initialized');
      return;
    }

    if (state.isSubmitting) {
      Log.info('setupPassword: already submitting');
      return;
    }

    _clearState(emit, true);

    final result = await passwordHttpService.setupPassword(
      newPassword: newPassword,
    );

    emit(
      state.copyWith(
        isSubmitting: false,
        hasPassword: result.fold(
          (success) => true,
          (error) => false,
        ),
        setupPasswordResult: result,
      ),
    );
  }

  Future<void> _onForgotPassword(
    Emitter<PasswordState> emit, {
    required String email,
  }) async {
    if (!_isInitialized) {
      Log.info('forgotPassword: not initialized');
      return;
    }

    if (state.isSubmitting) {
      Log.info('forgotPassword: already submitting');
      return;
    }

    _clearState(emit, true);

    final result = await passwordHttpService.forgotPassword(email: email);

    emit(
      state.copyWith(
        isSubmitting: false,
        forgotPasswordResult: result,
      ),
    );
  }

  Future<void> _onCheckHasPassword(Emitter<PasswordState> emit) async {
    if (!_isInitialized) {
      Log.info('checkHasPassword: not initialized');
      return;
    }

    if (state.isSubmitting) {
      Log.info('checkHasPassword: already submitting');
      return;
    }

    _clearState(emit, true);

    final result = await passwordHttpService.checkHasPassword();

    emit(
      state.copyWith(
        isSubmitting: false,
        hasPassword: result.fold(
          (success) => success,
          (error) => false,
        ),
        checkHasPasswordResult: result,
      ),
    );
  }

  void _clearState(Emitter<PasswordState> emit, bool isSubmitting) {
    emit(
      state.copyWith(
        isSubmitting: isSubmitting,
        changePasswordResult: null,
        setupPasswordResult: null,
        forgotPasswordResult: null,
        checkHasPasswordResult: null,
      ),
    );
  }
}

@freezed
class PasswordEvent with _$PasswordEvent {
  const factory PasswordEvent.init() = Init;

  // Change password
  const factory PasswordEvent.changePassword({
    required String oldPassword,
    required String newPassword,
  }) = ChangePassword;

  // Setup password
  const factory PasswordEvent.setupPassword({
    required String newPassword,
  }) = SetupPassword;

  // Forgot password
  const factory PasswordEvent.forgotPassword({
    required String email,
  }) = ForgotPassword;

  // Check has password
  const factory PasswordEvent.checkHasPassword() = CheckHasPassword;

  // Cancel operation
  const factory PasswordEvent.cancel() = Cancel;
}

@freezed
class PasswordState with _$PasswordState {
  const factory PasswordState({
    required bool isSubmitting,
    required bool hasPassword,
    required FlowyResult<bool, FlowyError>? changePasswordResult,
    required FlowyResult<bool, FlowyError>? setupPasswordResult,
    required FlowyResult<bool, FlowyError>? forgotPasswordResult,
    required FlowyResult<bool, FlowyError>? checkHasPasswordResult,
  }) = _PasswordState;

  factory PasswordState.initial() => const PasswordState(
        isSubmitting: false,
        hasPassword: false,
        changePasswordResult: null,
        setupPasswordResult: null,
        forgotPasswordResult: null,
        checkHasPasswordResult: null,
      );
}
