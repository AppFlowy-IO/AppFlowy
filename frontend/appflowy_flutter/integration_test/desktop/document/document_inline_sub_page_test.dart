import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

const _firstDocName = "Inline Sub Page Mention";
const _createdPageName = "hi world";

// Test cases that are covered in this file:
// - [x] Insert sub page mention from action menu (+)
// - [x] Delete sub page mention from editor
// - [x] Delete page from sidebar
// - [x] Delete page from sidebar and then trash
// - [x] Undo delete sub page mention
// - [x] Cut+paste in same document
// - [x] Cut+paste in different document
// - [x] Cut+paste in same document and then paste again in same document
// - [x] Turn paragraph with sub page mention into a heading
// - [x] Turn heading with sub page mention into a paragraph
// - [x] Duplicate a Block containing two sub page mentions

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document inline sub-page mention tests:', () {
    testWidgets('Insert (& delete) a sub page mention from action menu',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createOpenRenameDocumentUnderParent(name: _firstDocName);

      await tester.insertInlineSubPageFromPlusMenu();

      await tester.expandOrCollapsePage(
        pageName: _firstDocName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Delete from editor
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );

      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNothing);
      expect(find.byType(MentionSubPageBlock), findsNothing);

      // Undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);

      // Move to trash (delete from sidebar)
      await tester.rightClickOnPageName(_createdPageName);
      await tester.tapButtonWithName(ViewMoreActionType.delete.name);
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsOneWidget);
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(
        find.text(LocaleKeys.document_mention_trashHint.tr()),
        findsOneWidget,
      );

      // Delete from trash
      await tester.tapTrashButton();
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.trash_deleteAll.tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.button_delete.tr()));
      await tester.pumpAndSettle();

      await tester.openPage(_firstDocName);
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNothing);
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(
        find.text(LocaleKeys.document_mention_deletedPage.tr()),
        findsOneWidget,
      );
    });

    testWidgets(
        'Cut+paste in same document and cut+paste in different document',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createOpenRenameDocumentUnderParent(name: _firstDocName);

      await tester.insertInlineSubPageFromPlusMenu();

      await tester.expandOrCollapsePage(
        pageName: _firstDocName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Cut from editor
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNothing);
      expect(find.byType(MentionSubPageBlock), findsNothing);

      // Paste in same document
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Cut again
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      // Create another document
      const anotherDocName = "Another Document";
      await tester.createOpenRenameDocumentUnderParent(
        name: anotherDocName,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNothing);
      expect(find.byType(MentionSubPageBlock), findsNothing);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      // Paste in document
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpUntilFound(find.byType(MentionSubPageBlock));
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsOneWidget);

      await tester.expandOrCollapsePage(
        pageName: anotherDocName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);
    });
    testWidgets(
        'Cut+paste in same docuemnt and then paste again in same document',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createOpenRenameDocumentUnderParent(name: _firstDocName);

      await tester.insertInlineSubPageFromPlusMenu();

      await tester.expandOrCollapsePage(
        pageName: _firstDocName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Cut from editor
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNothing);
      expect(find.byType(MentionSubPageBlock), findsNothing);

      // Paste in same document
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Paste again
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsNWidgets(2));
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsNWidgets(2));
      expect(find.text('$_createdPageName (copy)'), findsNWidgets(2));
    });

    testWidgets('Turn into w/ sub page mentions', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createOpenRenameDocumentUnderParent(name: _firstDocName);

      await tester.insertInlineSubPageFromPlusMenu();

      await tester.expandOrCollapsePage(
        pageName: _firstDocName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      final headingText = LocaleKeys.document_slashMenu_name_heading1.tr();
      final paragraphText = LocaleKeys.document_slashMenu_name_text.tr();

      // Turn into heading
      await tester.editor.openTurnIntoMenu([0]);
      await tester.tapButton(find.findTextInFlowyText(headingText));
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);

      // Turn into paragraph
      await tester.editor.openTurnIntoMenu([0]);
      await tester.tapButton(find.findTextInFlowyText(paragraphText));
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsNWidgets(2));
      expect(find.byType(MentionSubPageBlock), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsOneWidget);
    });

    testWidgets('Duplicate a block containing two sub page mentions',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createOpenRenameDocumentUnderParent(name: _firstDocName);

      await tester.insertInlineSubPageFromPlusMenu();

      // Copy paste it
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: 1),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );

      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsOneWidget);
      expect(find.text("$_createdPageName (copy)"), findsOneWidget);
      expect(find.byType(MentionSubPageBlock), findsNWidgets(2));
      expect(find.byFlowySvg(FlowySvgs.child_page_s), findsNWidgets(2));

      // Duplicate node from block action menu
      await tester.editor.hoverAndClickOptionMenuButton([0]);
      await tester.tapButtonWithName(LocaleKeys.button_duplicate.tr());
      await tester.pumpAndSettle();

      expect(find.text(_createdPageName), findsOneWidget);
      expect(find.text("$_createdPageName (copy)"), findsNWidgets(2));
      expect(find.text("$_createdPageName (copy) (copy)"), findsOneWidget);
    });
  });
}

extension _InlineSubPageTestHelper on WidgetTester {
  Future<void> insertInlineSubPageFromPlusMenu() async {
    await editor.tapLineOfEditorAt(0);

    await editor.showPlusMenu();

    // Workaround to allow typing a document name
    await FlowyTestKeyboard.simulateKeyDownEvent(
      tester: this,
      withKeyUp: true,
      [
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyO,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyD,
      ],
    );

    await FlowyTestKeyboard.simulateKeyDownEvent(
      tester: this,
      withKeyUp: true,
      [LogicalKeyboardKey.enter],
    );
    await pumpUntilFound(find.byType(MentionSubPageBlock));
  }
}
