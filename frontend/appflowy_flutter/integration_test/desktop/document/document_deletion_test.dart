import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

import 'document_inline_page_reference_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document deletion', () {
    testWidgets('Trash breadcrumb', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // This test shares behavior with the inline page reference test, thus
      // we utilize the same helper functions there.
      final name = await createDocumentToReference(tester);
      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await triggerReferenceDocumentBySlashMenu(tester);

      // Search for prefix of document
      await enterDocumentText(tester);

      // Select result
      final optionFinder = find.descendant(
        of: find.byType(InlineActionsHandler),
        matching: find.text(name),
      );

      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);

      // Delete the page
      await tester.hoverOnPageName(name);
      await tester.tapDeletePageButton();
      await tester.pumpAndSettle();

      // Navigate to the deleted page from the inline mention
      await tester.tap(mentionBlock);
      await tester.pumpUntilFound(find.byType(TrashBreadcrumb));

      expect(find.byType(TrashBreadcrumb), findsOneWidget);

      // Navigate using the trash breadcrumb
      await tester.tap(
        find.descendant(
          of: find.byType(TrashBreadcrumb),
          matching: find.text(
            LocaleKeys.trash_text.tr(),
          ),
        ),
      );
      await tester.pumpUntilFound(find.text(LocaleKeys.trash_restoreAll.tr()));

      // Restore all
      await tester.tap(find.text(LocaleKeys.trash_restoreAll.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.trash_restore.tr()));
      await tester.pumpAndSettle();

      // Navigate back to the document
      await tester.openPage('Getting started');
      await tester.pumpAndSettle();

      await tester.tap(mentionBlock);
      await tester.pumpAndSettle();

      expect(find.byType(TrashBreadcrumb), findsNothing);
    });
  });
}
