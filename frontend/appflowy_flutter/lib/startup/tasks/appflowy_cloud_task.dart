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
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:url_protocol/url_protocol.dart';

class AppFlowyCloudDeepLink {
  final _appLinks = AppLinks();
  // The AppLinks is a singleton, so we need to cancel the previous subscription
  // before creating a new one.
  static StreamSubscription<Uri?>? _deeplinkSubscription;
  ValueNotifier<DeepLinkResult?>? _stateNotifier = ValueNotifier(null);
  Completer<Either<FlowyError, UserProfilePB>>? _completer;

  AppFlowyCloudDeepLink() {
    if (_deeplinkSubscription == null) {
      _deeplinkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) async {
          Log.info('onDeepLink: ${uri.toString()}');
          await _handleUri(uri);
        },
        onError: (Object err, StackTrace stackTrace) {
          Log.error('on deeplink stream error: ${err.toString()}', stackTrace);
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

  Future<void> dispose() async {
    _deeplinkSubscription?.pause();
    _stateNotifier?.dispose();
    _stateNotifier = null;
  }

  void resigerCompleter(
    Completer<Either<FlowyError, UserProfilePB>> completer,
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
    if (uri != null) {
      _isAuthCallbackDeeplink(uri).fold(
        (_) async {
          final deviceId = await getDeviceId();
          final payload = OauthSignInPB(
            authType: AuthenticatorPB.AppFlowyCloud,
            map: {
              AuthServiceMapKeys.signInURL: uri.toString(),
              AuthServiceMapKeys.deviceId: deviceId,
            },
          );
          _stateNotifier?.value = DeepLinkResult(state: DeepLinkState.loading);
          final result = await UserEventOauthSignIn(payload)
              .send()
              .then((value) => value.swap());

          _stateNotifier?.value = DeepLinkResult(
            state: DeepLinkState.finish,
            result: result,
          );
          // If there is no completer, runAppFlowy() will be called.
          if (_completer == null) {
            result.fold(
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
              (_) async {
                await runAppFlowy();
              },
            );
          } else {
            _completer?.complete(result);
            _completer = null;
          }
        },
        (err) {
          Log.error('onDeepLinkError: Unexpect deep link: $err');
          if (_completer == null) {
            final context = AppGlobals.rootNavKey.currentState?.context;
            if (context != null) {
              showSnackBarMessage(
                context,
                err.msg,
              );
            }
          } else {
            _completer?.complete(left(err));
            _completer = null;
          }
        },
      );
    } else {
      Log.error('onDeepLinkError: Unexpect empty deep link callback');
      _completer?.complete(left(AuthError.emptyDeeplink));
      _completer = null;
    }
  }

  Either<(), FlowyError> _isAuthCallbackDeeplink(Uri uri) {
    if (uri.fragment.contains('access_token')) {
      return left(());
    }

    return right(
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
  final DeepLinkState state;
  final Either<FlowyError, UserProfilePB>? result;

  DeepLinkResult({required this.state, this.result});
}

enum DeepLinkState {
  none,
  loading,
  finish,
}
