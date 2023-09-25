import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings: user icon tests', () {
    testWidgets('select icon, select default option', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      tester.expectToSeeHomePage();
      await tester.openSettings();

      await tester.openSettingsPage(SettingsPage.user);

      final userAvatarFinder = find.descendant(
        of: find.byType(SettingsUserView),
        matching: find.byType(UserAvatar),
      );

      // Open icon picker dialog
      await tester.tap(userAvatarFinder);
      await tester.pumpAndSettle();

      // Select first option that isn't default
      await tester.tap(find.byType(IconOption).first);
      await tester.pumpAndSettle();

      UserAvatar userAvatar = tester.widget(userAvatarFinder) as UserAvatar;
      expect(userAvatar.iconUrl, isNotEmpty);

      // Open icon picker dialog again
      await tester.tap(userAvatarFinder);
      await tester.pumpAndSettle();

      // Tap the default option
      await tester.tap(
        find.descendant(
          of: find.byType(IconGallery),
          matching: find.byType(UserAvatar),
        ),
      );
      await tester.pumpAndSettle();

      userAvatar = tester.widget(userAvatarFinder) as UserAvatar;
      expect(userAvatar.iconUrl, isEmpty);
    });
  });
}
