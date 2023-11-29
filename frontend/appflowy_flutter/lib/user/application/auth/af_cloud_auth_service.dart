import 'dart:async';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/backend_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_error.dart';

class AppFlowyCloudAuthService implements AuthService {
  AppFlowyCloudAuthService();

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
  Future<Either<FlowyError, UserProfilePB>> signInWithEmailPassword({
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
        if (isSuccess) {
          // The [AppFlowyCloudDeepLink] must be registered before using the
          // [AppFlowyCloudAuthService].
          if (getIt.isRegistered<AppFlowyCloudDeepLink>()) {
            getIt<AppFlowyCloudDeepLink>().resigerCompleter(completer);
          } else {
            throw Exception('AppFlowyCloudDeepLink is not registered');
          }
        } else {
          completer.complete(left(AuthError.signInWithOauthError));
        }

        return completer.future;
      },
      (r) => left(r),
    );
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
