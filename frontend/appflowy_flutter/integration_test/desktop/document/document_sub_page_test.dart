import 'dart:io';

import 'package:flutter/material.dart';
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
// - [x] Cut+paste a SubPageBlock in same Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [x] Cut+paste a SubPageBlock in different Document (Expect the view to be deleted on Cut, and brought back on Paste)
// - [x] Undo adding a SubPageBlock (Expect the view to be deleted)
// - [x] Undo delete of a SubPageBlock (Expect the view to be brought back to original position)
// - [x] Redo adding a SubPageBlock (Expect the view to be restored)
// - [x] Redo delete of a SubPageBlock (Expect the view to be moved to trash again)
// - [x] Renaming a child view (Expect the view name to be updated in the document)
// - [x] Deleting a view (to trash) linked to a SubPageBlock shows a hint that the view is in trash (Expect a hint to be shown)
// - [x] Deleting a view (in trash) linked to a SubPageBlock deletes the SubPageBlock (Expect the SubPageBlock to be deleted)
// - [x] Duplicating a SubPageBlock node from Action Menu (Expect a new view is created under current view with same content and name + (copy))
// - [x] Dragging a SubPageBlock node to a new position in the document (Expect everything to be normal)

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
        (tester) async {
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

    testWidgets('Delete with backspace (selected)', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu();

      expect(find.byType(SubPageBlockComponent), findsOneWidget);

      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(SubPageBlockComponent), findsNothing);
    });

    testWidgets('Copy+paste a SubPageBlock in same Document', (tester) async {
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
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SubPageBlockComponent), findsNWidgets(2));
      expect(find.text('Child page'), findsNWidgets(2));
      expect(find.text('Child page (copy)'), findsNWidgets(2));
    });

    testWidgets('Copy+paste a SubPageBlock in different Document',
        (tester) async {
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

      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(find.text('Child page'), findsOneWidget);
      expect(find.text('Child page (copy)'), findsNWidgets(2));
    });

    testWidgets('Cut+paste a SubPageBlock in same Document', (tester) async {
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

      await tester.editor
          .updateSelection(Selection.single(path: [0], startOffset: 0));

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNothing);
      expect(find.text('Child page'), findsNothing);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(find.text('Child page'), findsNWidgets(2));
    });

    testWidgets('Cut+paste a SubPageBlock in different Document',
        (tester) async {
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

      await tester.editor
          .updateSelection(Selection.single(path: [0], startOffset: 0));

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNothing);
      expect(find.text('Child page'), findsNothing);

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

      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(find.text('Child page'), findsNWidgets(2));
      expect(find.text('Child page (copy)'), findsNothing);
    });

    testWidgets('Undo adding a SubPageBlock', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu(true);

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.tapLineOfEditorAt(0);

      // Undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNothing);
      expect(find.text('Child page'), findsNothing);
    });

    testWidgets('Undo delete of a SubPageBlock', (tester) async {
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
      expect(find.byType(SubPageBlockComponent), findsNothing);

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));
      expect(find.byType(SubPageBlockComponent), findsOneWidget);
    });

    // Redo: undoing adding a subpage block, then redoing to bring it back
    // -> Add a subpage block
    // -> Undo
    // -> Redo
    testWidgets('Redo adding of a SubPageBlock', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu(true);

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      await tester.editor.tapLineOfEditorAt(0);

      // Undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNothing);
      expect(find.text('Child page'), findsNothing);

      // Redo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isShiftPressed: true,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(find.text('Child page'), findsNWidgets(2));
    });

    // Redo: undoing deleting a subpage block, then redoing to delete it again
    // -> Add a subpage block
    // -> Delete
    // -> Undo
    // -> Redo
    testWidgets('Redo delete of a SubPageBlock', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu(true);

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      await tester
          .hoverOnPageName(LocaleKeys.menuAppHeader_defaultNewPageName.tr());
      await tester.renamePage('Child page');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));

      // Delete
      await tester.editor.hoverAndClickOptionMenuButton([1]);
      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNothing);
      expect(find.byType(SubPageBlockComponent), findsNothing);

      await tester.editor.tapLineOfEditorAt(0);

      // Undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(find.text('Child page'), findsNWidgets(2));

      // Redo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isShiftPressed: true,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubPageBlockComponent), findsNothing);
      expect(find.text('Child page'), findsNothing);
    });

    testWidgets('Delete a view first to trash, then from trash',
        (tester) async {
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
      expect(find.byType(SubPageBlockComponent), findsOneWidget);

      final hintText = LocaleKeys.document_plugins_subPage_inTrashHint.tr();
      expect(find.text(hintText), findsNothing);

      await tester.hoverOnPageName('Child page');
      await tester.tapDeletePageButton();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(hintText), findsOne);

      // Go to trash
      await tester.tapTrashButton();
      await tester.pumpAndSettle();

      // Tap on delete all button
      await tester.tap(find.text(LocaleKeys.trash_deleteAll.tr()));
      await tester.pumpAndSettle();

      // Tap ok to delete app pages in trash
      await tester.tap(find.text(LocaleKeys.button_ok.tr()));
      await tester.pumpAndSettle();

      await tester.openPage('SubPageBlock');
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNothing);
      expect(find.byType(SubPageBlockComponent), findsNothing);
    });

    testWidgets('Duplicate SubPageBlock from Block Menu', (tester) async {
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

      await tester.tapButtonWithName(LocaleKeys.button_duplicate.tr());
      await tester.pumpAndSettle();

      expect(find.text('Child page'), findsNWidgets(2));
      expect(find.text('Child page (copy)'), findsNWidgets(2));
      expect(find.byType(SubPageBlockComponent), findsNWidgets(2));
    });

    testWidgets('Drag SubPageBlock to top of Document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(name: 'SubPageBlock');

      await tester.insertSubPageFromSlashMenu(true);

      await tester.expandOrCollapsePage(
        pageName: 'SubPageBlock',
        layout: ViewLayoutPB.Document,
      );

      expect(find.byType(SubPageBlockComponent), findsOneWidget);

      final beforeNode = tester.editor.getNodeAtPath([1]);

      await tester.editor.dragBlock([1], const Offset(20, -45));
      await tester.pumpAndSettle(Durations.long1);

      final afterNode = tester.editor.getNodeAtPath([0]);

      expect(afterNode.type, SubPageBlockKeys.type);
      expect(afterNode.type, beforeNode.type);
      expect(find.byType(SubPageBlockComponent), findsOneWidget);
      expect(
        find.text(LocaleKeys.document_plugins_subPage_inTrashHint.tr()),
        findsNothing,
      );
    });
  });
}

extension _SubPageTestHelper on WidgetTester {
  Future<void> insertSubPageFromSlashMenu([bool withTextNode = false]) async {
    await editor.tapLineOfEditorAt(0);

    if (withTextNode) {
      await ime.insertText('ABC');
      await editor.getCurrentEditorState().insertNewLine();
      await pumpAndSettle();
    }

    await editor.showSlashMenu();
    await editor.tapSlashMenuItemWithName(
      LocaleKeys.document_slashMenu_subPage_name.tr(),
      offset: 100,
    );

    await pumpUntilFound(find.byType(SubPageBlockComponent));
  }
}
