import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';
import '../board/board_hide_groups_test.dart';

const _firstDocName = "Inline Sub Page Mention";
const _createdPageName = "hi world";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document inline sub-page mention tests:', () {
    testWidgets('Insert (and delete) a sub page mention from action menu (+)',
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
      await tester.hoverOnPageName(_createdPageName);
      await tester.tapDeletePageButton();
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
      [LogicalKeyboardKey.enter],
    );
    await pumpUntilFound(find.byType(MentionSubPageBlock));
  }
}
