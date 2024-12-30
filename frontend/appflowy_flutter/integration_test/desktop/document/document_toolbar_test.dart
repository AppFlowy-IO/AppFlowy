import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document toolbar:', () {
    testWidgets('font family', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent();

      await tester.editor.tapLineOfEditorAt(0);
      const text = 'font family';
      await tester.ime.insertText(text);
      await tester.editor.updateSelection(
        Selection.single(
          path: [0],
          startOffset: 0,
          endOffset: text.length,
        ),
      );

      // tap the font family button
      final fontFamilyButton = find.byKey(kFontFamilyToolbarItemKey);
      await tester.tapButton(fontFamilyButton);

      // expect to see the font family dropdown immediately
      expect(find.byType(FontFamilyDropDown), findsOneWidget);

      // click the font family 'Abel'
      const abel = 'Abel';
      await tester.tapButton(find.text(abel));

      // check the text is updated to 'Abel'
      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.getDeltaAttributeValueInSelection(
          AppFlowyRichTextKeys.fontFamily,
        ),
        abel,
      );
    });
  });
}
