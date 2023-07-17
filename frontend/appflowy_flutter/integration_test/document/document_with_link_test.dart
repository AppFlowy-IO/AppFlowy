import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/ime.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('inline page view in document', () {
    testWidgets('insert a inline page - grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document
      await tester.createNewPageWithName(
        ViewLayoutPB.Document,
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a inline page
      const link = 'AppFlowy';
      await tester.ime.insertText(link);
      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: link.length),
      );

      // tap the inline math equation button
      final linkButton = find.byTooltip(
        'Link',
      );
      await tester.tapButton(linkButton);
      expect(find.text('Add your link', findRichText: true), findsOneWidget);
    });
  });
}
