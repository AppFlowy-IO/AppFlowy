import 'dart:ui';

import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings: user language tests', () {
    testWidgets('select language, language changed', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      await tester.expectToSeeHomePageWithGetStartedPage();
      await tester.openSettings();

      await tester.openSettingsPage(SettingsPage.language);

      final userLanguageFinder = find.descendant(
        of: find.byType(SettingsLanguageView),
        matching: find.byType(LanguageSelector),
      );

      // Grab current locale
      LanguageSelector userLanguage =
          tester.widget<LanguageSelector>(userLanguageFinder);
      Locale currentLocale = userLanguage.currentLocale;

      // Open language selector
      await tester.tap(userLanguageFinder);
      await tester.pumpAndSettle();

      // Select first option that isn't default
      await tester.tap(find.byType(LanguageItem).at(1));
      await tester.pumpAndSettle();

      // Make sure the new locale is not the same as previous one
      userLanguage = tester.widget<LanguageSelector>(userLanguageFinder);
      expect(
        userLanguage.currentLocale,
        isNot(equals(currentLocale)),
        reason: "new language shouldn't equal the previous selected language",
      );

      // Update the current locale to a new one
      currentLocale = userLanguage.currentLocale;

      // Tried the same flow for the second time
      // Open language selector
      await tester.tap(userLanguageFinder);
      await tester.pumpAndSettle();

      // Select second option that isn't default
      await tester.tap(find.byType(LanguageItem).at(2));
      await tester.pumpAndSettle();

      // Make sure the new locale is not the same as previous one
      userLanguage = tester.widget<LanguageSelector>(userLanguageFinder);
      expect(
        userLanguage.currentLocale,
        isNot(equals(currentLocale)),
        reason: "new language shouldn't equal the previous selected language",
      );
    });
  });
}
