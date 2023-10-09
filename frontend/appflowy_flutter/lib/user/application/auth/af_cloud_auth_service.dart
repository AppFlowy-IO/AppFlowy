import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:appflowy/user/application/auth/backend_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_error.dart';
import 'device_id.dart';

class AFCloudAuthService implements AuthService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri?>? _deeplinkSubscription;

  AFCloudAuthService();

  final BackendAuthService _backendAuthService = BackendAuthService(
    AuthTypePB.AFCloud,
  );

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    Map<String, String> params = const {},
  }) async {
    final provider = ProviderTypePBExtension.fromPlatform(platform);

    // Get the oauth url from the backend
    final result = await UserEventGetOauthURLWithProvider(
      OauthProviderPB.create()..provider = provider,
    ).send();

    return result.fold(
      (data) async {
        // Open the webview with oauth url
        final uri = Uri.parse(data.oauthUrl);
        final isSuccess = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_self',
        );

        final completer = Completer<Either<FlowyError, UserProfilePB>>();
        _deeplinkSubscription = _appLinks.uriLinkStream.listen(
          (Uri? uri) async {
            await _handleUri(uri, completer);
          },
          onError: (Object err, StackTrace stackTrace) {
            Log.error('onDeepLinkError: ${err.toString()}', stackTrace);
            _deeplinkSubscription?.cancel();
            completer.complete(left(AuthError.deeplinkError));
          },
        );

        if (!isSuccess) {
          _deeplinkSubscription?.cancel();
          completer.complete(left(AuthError.signInWithOauthError));
        }

        return completer.future;
      },
      (r) => left(r),
    );
  }

  Future<void> _handleUri(
    Uri? uri,
    Completer<Either<FlowyError, UserProfilePB>> completer,
  ) async {
    if (uri != null) {
      if (_isAuthCallbackDeeplink(uri)) {
        // Sign in with url
        final deviceId = await getDeviceId();
        final payload = OauthSignInPB(
          authType: AuthTypePB.AFCloud,
          map: {
            AuthServiceMapKeys.signInURL: uri.toString(),
            AuthServiceMapKeys.deviceId: deviceId
          },
        );
        final result = await UserEventOauthSignIn(payload)
            .send()
            .then((value) => value.swap());
        _deeplinkSubscription?.cancel();
        completer.complete(result);
      }
    } else {
      Log.error('onDeepLinkError: Unexpect empty deep link callback');
      _deeplinkSubscription?.cancel();
      completer.complete(left(AuthError.emptyDeeplink));
    }
  }

  @override
  Future<void> signOut() async {
    await _backendAuthService.signOut();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    return _backendAuthService.signUpAsGuest();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }
}

extension ProviderTypePBExtension on ProviderTypePB {
  static ProviderTypePB fromPlatform(String platform) {
    switch (platform) {
      case 'github':
        return ProviderTypePB.Github;
      case 'google':
        return ProviderTypePB.Google;
      case 'discord':
        return ProviderTypePB.Discord;
      default:
        throw UnimplementedError();
    }
  }
}

bool _isAuthCallbackDeeplink(Uri uri) {
  return (uri.fragment.contains('access_token'));
}
