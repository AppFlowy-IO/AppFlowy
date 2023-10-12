import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';

class InitAppFlowyCloudTask extends LaunchTask {
  final _authStateListener = UserAuthStateListener();
  bool isLoggingOut = false;

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isAppFlowyCloudEnabled) {
      return;
    }

    _authStateListener.start(
      didSignIn: () {
        isLoggingOut = false;
      },
      onInvalidAuth: (message) async {
        await getIt<AuthService>().signOut();
        if (!isLoggingOut) {
          await runAppFlowy();
        }
      },
    );
  }
}
