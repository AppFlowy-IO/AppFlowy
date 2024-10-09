import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';
import 'document_inline_page_reference_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document deletion', () {
    testWidgets('Trash breadcrumbs', (tester) async {
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

      await tester.expandOrCollapsePage(
        pageName: 'Getting started',
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      // Delete the page
      await tester.hoverOnPageName(name);
      await tester.tapDeletePageButton();
      await tester.pumpAndSettle();

      // Navigate to the deleted page from the inline mention
      await tester.tap(mentionBlock);
      await tester.pumpAndSettle();

      expect(find.byType(DocumentBanner), findsOneWidget);
      expect(find.byType(TrashBreadcrumb), findsOneWidget);
    });
  });
}
