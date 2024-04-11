import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('edit document', () {
    testWidgets('redo & undo', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document called Sample
      const pageName = 'Sample';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.editor.tapLineOfEditorAt(0);

      // insert 1. to trigger it to be a numbered list
      await tester.ime.insertText('1. ');
      expect(find.text('1.', findRichText: true), findsOneWidget);
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([0])!.type,
        NumberedListBlockKeys.type,
      );

      // undo
      // numbered list will be reverted to paragraph
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isWindows || Platform.isLinux,
        isMetaPressed: Platform.isMacOS,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([0])!.type,
        ParagraphBlockKeys.type,
      );

      // redo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isWindows || Platform.isLinux,
        isMetaPressed: Platform.isMacOS,
        isShiftPressed: true,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([0])!.type,
        NumberedListBlockKeys.type,
      );

      // switch to other page and switch back
      await tester.openPage(gettingStarted);
      await tester.openPage(pageName);

      // the numbered list should be kept
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([0])!.type,
        NumberedListBlockKeys.type,
      );
    });

    testWidgets('write a readme document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document called Sample
      const pageName = 'Sample';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.editor.tapLineOfEditorAt(0);

      // mock inputting the sample
      final lines = _sample.split('\n');
      for (final line in lines) {
        await tester.ime.insertText(line);
        await tester.ime.insertCharacter('\n');
      }

      // switch to other page and switch back
      await tester.openPage(gettingStarted);
      await tester.openPage(pageName);

      // this screenshots are different on different platform, so comment it out temporarily.
      // check the document
      // await expectLater(
      //   find.byType(AppFlowyEditor),
      //   matchesGoldenFile('document/edit_document_test.png'),
      // );
    });
  });
}

const _sample = '''
# Heading 1
## Heading 2
### Heading 3
---
[] Highlight any text, and use the editing menu to _style_ **your** writing `however` you ~~like.~~

[] Type followed by bullet or num to create a list.

[x] Click `New Page` button at the bottom of your sidebar to add a new page.

[] Click the plus sign next to any page title in the sidebar to quickly add a new subpage, `Document`, `Grid`, or `Kanban Board`.
---
* bulleted list 1

* bulleted list 2

* bulleted list 3
bulleted list 4
---
1. numbered list 1

2. numbered list 2

3. numbered list 3
numbered list 4
---
" quote''';
