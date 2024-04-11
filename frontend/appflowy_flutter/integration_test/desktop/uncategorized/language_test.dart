import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document', () {
    testWidgets(
        'change the language successfully when launching the app for the first time',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapLanguageSelectorOnWelcomePage();
      expect(find.byType(LanguageItemsListView), findsOneWidget);

      await tester.tapLanguageItem(languageCode: 'zh', countryCode: 'CN');
      tester.expectToSeeText('开始');

      await tester.tapLanguageItem(languageCode: 'en', scrollDelta: -100);
      tester.expectToSeeText('Quick Start');

      await tester.tapLanguageItem(languageCode: 'it', countryCode: 'IT');
      tester.expectToSeeText('Andiamo');
    });

    /// Make sure this test is executed after the test above.
    testWidgets('check the language after relaunching the app', (tester) async {
      await tester.initializeAppFlowy();
      tester.expectToSeeText('Andiamo');
    });
  });
}
