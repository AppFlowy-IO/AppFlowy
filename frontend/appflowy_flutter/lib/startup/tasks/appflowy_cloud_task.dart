import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/startup/tasks/supabase_task.dart';
import 'package:appflowy/user/application/auth/auth_error.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';
import 'package:url_protocol/url_protocol.dart';

class AppFlowyCloudDeepLink {
  AppFlowyCloudDeepLink() {
    if (_deeplinkSubscription == null) {
      _deeplinkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) async {
          Log.info('onDeepLink: ${uri.toString()}');
          await _handleUri(uri);
        },
        onError: (Object err, StackTrace stackTrace) {
          Log.error('on DeepLink stream error: ${err.toString()}', stackTrace);
          _deeplinkSubscription?.cancel();
          _deeplinkSubscription = null;
        },
      );
      if (Platform.isWindows) {
        // register deep link for Windows
        registerProtocolHandler(appflowyDeepLinkSchema);
      }
    } else {
      _deeplinkSubscription?.resume();
    }
  }

  final _appLinks = AppLinks();

  ValueNotifier<DeepLinkResult?>? _stateNotifier = ValueNotifier(null);
  Completer<FlowyResult<UserProfilePB, FlowyError>>? _completer;

  // The AppLinks is a singleton, so we need to cancel the previous subscription
  // before creating a new one.
  static StreamSubscription<Uri?>? _deeplinkSubscription;

  Future<void> dispose() async {
    _deeplinkSubscription?.pause();
    _stateNotifier?.dispose();
    _stateNotifier = null;
  }

  void registerCompleter(
    Completer<FlowyResult<UserProfilePB, FlowyError>> completer,
  ) {
    _completer = completer;
  }

  VoidCallback subscribeDeepLinkLoadingState(
    ValueChanged<DeepLinkResult> listener,
  ) {
    void listenerFn() {
      if (_stateNotifier?.value != null) {
        listener(_stateNotifier!.value!);
      }
    }

    _stateNotifier?.addListener(listenerFn);
    return listenerFn;
  }

  void unsubscribeDeepLinkLoadingState(VoidCallback listener) =>
      _stateNotifier?.removeListener(listener);

  Future<void> _handleUri(
    Uri? uri,
  ) async {
    _stateNotifier?.value = DeepLinkResult(state: DeepLinkState.none);

    if (uri == null) {
      Log.error('onDeepLinkError: Unexpected empty deep link callback');
      _completer?.complete(FlowyResult.failure(AuthError.emptyDeepLink));
      _completer = null;
      return;
    }

    return _isAuthCallbackDeepLink(uri).fold(
      (_) async {
        final deviceId = await getDeviceId();
        final payload = OauthSignInPB(
          authenticator: AuthenticatorPB.AppFlowyCloud,
          map: {
            AuthServiceMapKeys.signInURL: uri.toString(),
            AuthServiceMapKeys.deviceId: deviceId,
          },
        );
        _stateNotifier?.value = DeepLinkResult(state: DeepLinkState.loading);
        final result = await UserEventOauthSignIn(payload).send();

        _stateNotifier?.value = DeepLinkResult(
          state: DeepLinkState.finish,
          result: result,
        );
        // If there is no completer, runAppFlowy() will be called.
        if (_completer == null) {
          await result.fold(
            (_) async {
              await runAppFlowy();
            },
            (err) {
              Log.error(err);
              final context = AppGlobals.rootNavKey.currentState?.context;
              if (context != null) {
                showSnackBarMessage(
                  context,
                  err.msg,
                );
              }
            },
          );
        } else {
          _completer?.complete(result);
          _completer = null;
        }
      },
      (err) {
        Log.error('onDeepLinkError: Unexpected deep link: $err');
        if (_completer == null) {
          final context = AppGlobals.rootNavKey.currentState?.context;
          if (context != null) {
            showSnackBarMessage(
              context,
              err.msg,
            );
          }
        } else {
          _completer?.complete(FlowyResult.failure(err));
          _completer = null;
        }
      },
    );
  }

  FlowyResult<void, FlowyError> _isAuthCallbackDeepLink(Uri uri) {
    if (uri.fragment.contains('access_token')) {
      return FlowyResult.success(null);
    }

    return FlowyResult.failure(
      FlowyError.create()
        ..code = ErrorCode.MissingAuthField
        ..msg = uri.path,
    );
  }
}

class InitAppFlowyCloudTask extends LaunchTask {
  UserAuthStateListener? _authStateListener;
  bool isLoggingOut = false;

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isAppFlowyCloudEnabled) {
      return;
    }
    _authStateListener = UserAuthStateListener();

    _authStateListener?.start(
      didSignIn: () {
        isLoggingOut = false;
      },
      onInvalidAuth: (message) async {
        Log.error(message);
        if (!isLoggingOut) {
          await runAppFlowy();
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    await _authStateListener?.stop();
    _authStateListener = null;
  }
}

class DeepLinkResult {
  DeepLinkResult({
    required this.state,
    this.result,
  });

  final DeepLinkState state;
  final FlowyResult<UserProfilePB, FlowyError>? result;
}

enum DeepLinkState {
  none,
  loading,
  finish,
}
