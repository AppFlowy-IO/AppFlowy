import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title:', () {
    testWidgets('create a new page, the title should be empty', (tester) async {
      await tester.launchInAnonymousMode();

      final createPageButton = find.byKey(
        BottomNavigationBarItemType.add.valueKey,
      );
      await tester.tapButton(createPageButton);
      expect(find.byType(MobileDocumentScreen), findsOneWidget);

      final title = tester.editor.findDocumentTitle('');
      expect(title, findsOneWidget);
      final textField = tester.widget<TextField>(title);
      expect(textField.focusNode!.hasFocus, isTrue);

      // input new name and press done button
      const name = 'test document';
      await tester.enterText(title, name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final newTitle = tester.editor.findDocumentTitle(name);
      expect(newTitle, findsOneWidget);
      expect(textField.controller!.text, name);

      // the document should get focus
      final editor = tester.widget<AppFlowyEditorPage>(
        find.byType(AppFlowyEditorPage),
      );
      expect(
        editor.editorState.selection,
        Selection.collapsed(Position(path: [0])),
      );
    });
  });
}
