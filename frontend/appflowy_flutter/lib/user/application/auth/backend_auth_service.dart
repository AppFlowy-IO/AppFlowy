import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'device_id.dart';

class BackendAuthService implements AuthService {
  BackendAuthService(this.authType);

  final AuthenticatorPB authType;

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>>
      signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignInPayloadPB.create()
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();
    return UserEventSignInWithEmailPassword(request).send();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignUpPayloadPB.create()
      ..name = name
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();
    final response = await UserEventSignUp(request).send().then(
          (value) => value,
        );
    return response;
  }

  @override
  Future<void> signOut({
    Map<String, String> params = const {},
  }) async {
    await UserEventSignOut().send();
    return;
  }

  @override
  Future<void> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    await runAppFlowy(isAnon: true);
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    AuthenticatorPB authType = AuthenticatorPB.Local,
    Map<String, String> params = const {},
  }) async {
    return FlowyResult.failure(
      FlowyError.create()
        ..code = ErrorCode.Internal
        ..msg = "Unsupported sign up action",
    );
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    // No need to pass the redirect URL.
    return UserBackendService.signInWithMagicLink(email, '');
  }

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>> signInWithPasscode({
    required String email,
    required String passcode,
  }) async {
    return UserBackendService.signInWithPasscode(email, passcode);
  }
}
