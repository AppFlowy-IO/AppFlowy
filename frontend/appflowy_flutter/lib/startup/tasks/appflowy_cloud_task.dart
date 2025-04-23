import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/invitation_deeplink_hanlder.dart';
import 'package:appflowy/startup/tasks/deeplink/login_deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/payment_deeplink_handler.dart';
import 'package:appflowy/user/application/auth/auth_error.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';
import 'package:url_protocol/url_protocol.dart';

const appflowyDeepLinkSchema = 'appflowy-flutter';

class AppFlowyCloudDeepLink {
  AppFlowyCloudDeepLink() {
    _deepLinkHandlerRegistry = DeepLinkHandlerRegistry.instance
      ..register(LoginDeepLinkHandler())
      ..register(PaymentDeepLinkHandler())
      ..register(InvitationDeepLinkHandler());

    _deepLinkSubscription = _AppLinkWrapper.instance.listen(
      (Uri? uri) async {
        Log.info('onDeepLink: ${uri.toString()}');
        await _handleUri(uri);
      },
      onError: (Object err, StackTrace stackTrace) {
        Log.error('on DeepLink stream error: ${err.toString()}', stackTrace);
        _deepLinkSubscription.cancel();
      },
    );
    if (Platform.isWindows) {
      // register deep link for Windows
      registerProtocolHandler(appflowyDeepLinkSchema);
    }
  }

  ValueNotifier<DeepLinkResult?>? _stateNotifier = ValueNotifier(null);

  Completer<FlowyResult<UserProfilePB, FlowyError>>? _completer;

  set completer(Completer<FlowyResult<UserProfilePB, FlowyError>>? value) {
    Log.debug('AppFlowyCloudDeepLink: $hashCode completer');
    _completer = value;
  }

  late final StreamSubscription<Uri?> _deepLinkSubscription;
  late final DeepLinkHandlerRegistry _deepLinkHandlerRegistry;

  Future<void> dispose() async {
    Log.debug('AppFlowyCloudDeepLink: $hashCode dispose');
    await _deepLinkSubscription.cancel();

    _stateNotifier?.dispose();
    _stateNotifier = null;
    completer = null;
  }

  void registerCompleter(
    Completer<FlowyResult<UserProfilePB, FlowyError>> completer,
  ) {
    this.completer = completer;
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

  Future<void> passGotrueTokenResponse(
    GotrueTokenResponsePB gotrueTokenResponse,
  ) async {
    final uri = _buildDeepLinkUri(gotrueTokenResponse);
    await _handleUri(uri);
  }

  Future<void> _handleUri(
    Uri? uri,
  ) async {
    _stateNotifier?.value = DeepLinkResult(state: DeepLinkState.none);

    if (uri == null) {
      Log.error('onDeepLinkError: Unexpected empty deep link callback');
      _completer?.complete(FlowyResult.failure(AuthError.emptyDeepLink));
      completer = null;
      return;
    }

    await _deepLinkHandlerRegistry.processDeepLink(
      uri: uri,
      onStateChange: (handler, state) {
        // only handle the login deep link
        if (handler is LoginDeepLinkHandler) {
          _stateNotifier?.value = DeepLinkResult(state: state);
        }
      },
      onResult: (handler, result) async {
        if (handler is LoginDeepLinkHandler &&
            result is FlowyResult<UserProfilePB, FlowyError>) {
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
                  showToastNotification(
                    message: err.msg,
                  );
                }
              },
            );
          } else {
            _completer?.complete(result);
            completer = null;
          }
        }
      },
      onError: (error) {
        Log.error('onDeepLinkError: Unexpected deep link: $error');
        if (_completer == null) {
          final context = AppGlobals.rootNavKey.currentState?.context;
          if (context != null) {
            showToastNotification(
              message: error.msg,
              type: ToastificationType.error,
            );
          }
        } else {
          _completer?.complete(FlowyResult.failure(error));
          completer = null;
        }
      },
    );
  }

  Uri? _buildDeepLinkUri(GotrueTokenResponsePB gotrueTokenResponse) {
    final params = <String, String>{};

    if (gotrueTokenResponse.hasAccessToken() &&
        gotrueTokenResponse.accessToken.isNotEmpty) {
      params['access_token'] = gotrueTokenResponse.accessToken;
    }

    if (gotrueTokenResponse.hasExpiresAt()) {
      params['expires_at'] = gotrueTokenResponse.expiresAt.toString();
    }

    if (gotrueTokenResponse.hasExpiresIn()) {
      params['expires_in'] = gotrueTokenResponse.expiresIn.toString();
    }

    if (gotrueTokenResponse.hasProviderRefreshToken() &&
        gotrueTokenResponse.providerRefreshToken.isNotEmpty) {
      params['provider_refresh_token'] =
          gotrueTokenResponse.providerRefreshToken;
    }

    if (gotrueTokenResponse.hasProviderAccessToken() &&
        gotrueTokenResponse.providerAccessToken.isNotEmpty) {
      params['provider_token'] = gotrueTokenResponse.providerAccessToken;
    }

    if (gotrueTokenResponse.hasRefreshToken() &&
        gotrueTokenResponse.refreshToken.isNotEmpty) {
      params['refresh_token'] = gotrueTokenResponse.refreshToken;
    }

    if (gotrueTokenResponse.hasTokenType() &&
        gotrueTokenResponse.tokenType.isNotEmpty) {
      params['token_type'] = gotrueTokenResponse.tokenType;
    }

    if (params.isEmpty) {
      return null;
    }

    final fragment = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return Uri.parse('appflowy-flutter://login-callback#$fragment');
  }
}

class InitAppFlowyCloudTask extends LaunchTask {
  UserAuthStateListener? _authStateListener;
  bool isLoggingOut = false;

  @override
  Future<void> initialize(LaunchContext context) async {
    await super.initialize(context);

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
    await super.dispose();

    await _authStateListener?.stop();
    _authStateListener = null;
  }
}

// wrapper for AppLinks to support multiple listeners
class _AppLinkWrapper {
  _AppLinkWrapper._() {
    _appLinkSubscription = _appLinks.uriLinkStream.listen((event) {
      _streamSubscription.sink.add(event);
    });
  }

  static final _AppLinkWrapper instance = _AppLinkWrapper._();

  final AppLinks _appLinks = AppLinks();
  final _streamSubscription = StreamController<Uri?>.broadcast();
  late final StreamSubscription<Uri?> _appLinkSubscription;

  StreamSubscription<Uri?> listen(
    void Function(Uri?) listener, {
    Function? onError,
    bool? cancelOnError,
  }) {
    return _streamSubscription.stream.listen(
      listener,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }

  void dispose() {
    _streamSubscription.close();
    _appLinkSubscription.cancel();
  }
}
