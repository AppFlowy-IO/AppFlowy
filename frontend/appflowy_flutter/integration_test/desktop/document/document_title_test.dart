import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title', () {
    testWidgets(
        'create a new document, the title will be displayed at the first line',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      const name = 'Hello World';
      final title = find.text('Untitled');
      expect(title, findsOneWidget);

      // input name
      await tester.enterText(title, name);
      await tester.pumpAndSettle();

      final newTitle = find.text(name);
      expect(newTitle, findsOneWidget);

      // press enter to create a new line
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      const firstLine = 'This is the first line';
      await tester.ime.insertText(firstLine);
      await tester.pumpAndSettle();

      final firstLineText = find.text(firstLine);
      expect(firstLineText, findsOneWidget);
    });
  });
}
