import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/rich_text/quoted_text.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('format_rich_text_style.dart', () {
    testWidgets('formatTextNodes', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: text.length),
      );

      // format the text to Quote
      formatTextNodes(editor.editorState, {
        BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote,
      });
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(QuotedTextNodeWidget), findsOneWidget);

      // format the text to Quote again. The style should be removed.
      formatTextNodes(editor.editorState, {
        BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote,
      });
      await tester.pumpAndSettle();
      expect(find.byType(QuotedTextNodeWidget), findsNothing);
    });
  });
}
