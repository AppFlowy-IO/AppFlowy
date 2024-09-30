import 'dart:io';

import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

// Test cases for the Document SubPageBlock that needs to be covered:
// - [x] Insert a new SubPageBlock from Slash menu items (Expect it will create a child view under current view)
// - [x] Delete a SubPageBlock from Block Action Menu (Expect the view is moved to trash / deleted)
// - [x] Delete a SubPageBlock with backspace when selected (Expect the view is moved to trash / deleted)
// - [x] Copy+paste a SubPageBlock in same Document (Expect a new view is created under current view with same content and name)
// - [x] Copy+paste a SubPageBlock in different Document (Expect a new view is created under current view with same content and name)
// - [ ] Cut+paste a SubPageBlock in same Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [ ] Cut+paste a SubPageBlock in different Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [ ] Undo delete of a SubPageBlock (Expect the view to be brought back to original position)
// - [ ] Redo delete of a SubPageBlock (Expect the view to be moved to trash again)
// - [x] Renaming a child view (Expect the view name to be updated in the document)
// - [ ] Deleting a view (to trash) linked to a SubPageBlock shows a hint that the view is in trash (Expect a hint to be shown)
// - [ ] Deleting a view (in trash) linked to a SubPageBlock deletes the SubPageBlock (Expect the SubPageBlock to be deleted)
// - [ ] Dragging a SubPageBlock node to a new position in the document (Expect everything to be normal)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document SubPageBlock tests', () {
    testWidgets('Insert a new SubPageBlock from Slash menu items',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      expect(
        find.text(LocaleKeys.menuAppHeader_defaultNewPageName.tr()),
        findsNWidgets(3),
      );
    });

    testWidgets('Rename and then Delete a SubPageBlock from Block Action Menu',
        (WidgetTester tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.hoverAndClickOptionMenuButton([0]);

      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNothing);
    });

    testWidgets('Delete a SubPageBlock with backspace when selected',
        (WidgetTester tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );
      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNothing);
      expect(find.byType(SubPageBlockComponent), findsNothing);
    });

    testWidgets('Copy+paste a SubPageBlock in same Document',
        (WidgetTester tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.hoverAndClickOptionAddButton([0], false);
      await tester.editor.tapLineOfEditorAt(1);

      // This is a workaround to allow CTRL+A and CTRL+C to work to copy
      // the SubPageBlock as well.
      await tester.ime.insertText('ABC');

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.editor.hoverAndClickOptionAddButton([1], false);
      await tester.editor.tapLineOfEditorAt(2);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNWidgets(2));
      expect(find.text('Child page'), findsNWidgets(2));
      expect(find.text('Child page (copy)'), findsNWidgets(2));
    });

    testWidgets('Copy+paste a SubPageBlock in different Document',
        (WidgetTester tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.hoverAndClickOptionAddButton([0], false);
      await tester.editor.tapLineOfEditorAt(1);

      // This is a workaround to allow CTRL+A and CTRL+C to work to copy
      // the SubPageBlock as well.
      await tester.ime.insertText('ABC');

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock-2');

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock-2',
        layout: ViewLayoutPB.Document,
      );

      expect(find.byType(SubPageBlockComponent), findsNWidgets(1));
      expect(find.text('Child page'), findsNWidgets(1));
      expect(find.text('Child page (copy)'), findsNWidgets(2));
    });

    testWidgets('Cut+paste a SubPageBlock in same Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Cut+paste a SubPageBlock in different Document',
        (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Undo delete of a SubPageBlock', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Redo delete of a SubPageBlock', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Deleting a view (to trash)', (WidgetTester tester) async {
      // Test code goes here.
    });

    testWidgets('Deleting a view (in trash)', (WidgetTester tester) async {
      // Test code goes here.
    });
  });
}

extension _SubPageTestHelper on WidgetTester {
  Future<void> insertSubPageFromSlashMenu() async {
    await editor.tapLineOfEditorAt(0);
    await editor.showSlashMenu();
    await editor.tapSlashMenuItemWithName(
      LocaleKeys.document_slashMenu_subPage_name.tr(),
      offset: 100,
    );

    await pumpUntilFound(find.byType(SubPageBlockComponent));
  }
}
