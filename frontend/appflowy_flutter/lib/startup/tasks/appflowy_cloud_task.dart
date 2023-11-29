import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/supabase_task.dart';
import 'package:appflowy/user/application/auth/auth_error.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy_backend/log.dart';
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
  final List<Completer<Either<FlowyError, UserProfilePB>>> _completers = [];

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

  void resigerCompleter(
    Completer<Either<FlowyError, UserProfilePB>> completer,
  ) {
    _completers.add(completer);
  }

  void unregisterCompleter(
    Completer<Either<FlowyError, UserProfilePB>> completer,
  ) {
    _completers.remove(completer);
  }

  Future<void> _handleUri(
    Uri? uri,
  ) async {
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
        final result = await UserEventOauthSignIn(payload)
            .send()
            .then((value) => value.swap());

        if (_completers.isEmpty) {
          result.fold((l) => null, (r) => null);
          await runAppFlowy();
        } else {
          for (final completer in _completers) {
            completer.complete(result);
          }
        }
      } else {
        Log.error('onDeepLinkError: Unexpect deep link: ${uri.toString()}');
        for (final completer in _completers) {
          completer.complete(left(AuthError.signInWithOauthError));
        }
      }
    } else {
      Log.error('onDeepLinkError: Unexpect empty deep link callback');
      for (final completer in _completers) {
        completer.complete(left(AuthError.emptyDeeplink));
      }
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
