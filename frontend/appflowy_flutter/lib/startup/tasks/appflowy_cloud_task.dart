import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/startup/tasks/supabase_task.dart';
import 'package:appflowy/user/application/auth/auth_error.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:url_protocol/url_protocol.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';

class AppFlowyCloudDeepLink {
  final _appLinks = AppLinks();
  StreamSubscription<Uri?>? _deeplinkSubscription;
  final ValueNotifier<DeepLinkResult?> stateNotifier = ValueNotifier(null);
  Completer<Either<FlowyError, UserProfilePB>>? _completer;

  AppFlowyCloudDeepLink() {
    if (Platform.isWindows) {
      // register deep link for Windows
      registerProtocolHandler(appflowyDeepLinkSchema);
    }

    _deeplinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) async {
        Log.info('onDeepLink: ${uri.toString()}');
        await _handleUri(uri);
      },
      onError: (Object err, StackTrace stackTrace) {
        Log.error('on deeplink stream error: ${err.toString()}', stackTrace);
        _deeplinkSubscription?.cancel();
      },
    );
  }

  Future<void> dispose() async {
    await _deeplinkSubscription?.cancel();
  }

  void resigerCompleter(
    Completer<Either<FlowyError, UserProfilePB>> completer,
  ) {
    _completer = completer;
  }

  VoidCallback subscribeDeepLinkLoadingState(
    ValueChanged<DeepLinkResult> listener,
  ) {
    listenerFn() {
      if (stateNotifier.value != null) {
        listener(stateNotifier.value!);
      }
    }

    stateNotifier.addListener(listenerFn);
    return listenerFn;
  }

  void unsubscribeDeepLinkLoadingState(
    VoidCallback listener,
  ) {
    stateNotifier.removeListener(listener);
  }

  Future<void> _handleUri(
    Uri? uri,
  ) async {
    stateNotifier.value = DeepLinkResult(state: DeepLinkState.none);
    if (uri != null) {
      if (_isAuthCallbackDeeplink(uri)) {
        final deviceId = await getDeviceId();
        final payload = OauthSignInPB(
          authType: AuthTypePB.AFCloud,
          map: {
            AuthServiceMapKeys.signInURL: uri.toString(),
            AuthServiceMapKeys.deviceId: deviceId,
          },
        );
        stateNotifier.value = DeepLinkResult(state: DeepLinkState.loading);
        final result = await UserEventOauthSignIn(payload)
            .send()
            .then((value) => value.swap());

        stateNotifier.value = DeepLinkResult(
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
            (err) async {
              Log.error(err);
              await runAppFlowy();
            },
          );
        } else {
          _completer?.complete(result);
          _completer = null;
        }
      } else {
        Log.error('onDeepLinkError: Unexpect deep link: ${uri.toString()}');
        _completer?.complete(left(AuthError.signInWithOauthError));
        _completer = null;
      }
    } else {
      Log.error('onDeepLinkError: Unexpect empty deep link callback');
      _completer?.complete(left(AuthError.emptyDeeplink));
      _completer = null;
    }
  }

  bool _isAuthCallbackDeeplink(Uri uri) {
    return (uri.fragment.contains('access_token'));
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
