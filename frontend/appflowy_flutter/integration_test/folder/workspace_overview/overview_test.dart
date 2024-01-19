import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/workspace_overview/overview_block_component.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String firstLevelParentViewName = 'Overview Test';

  group("workspace overview block test", () {
    testWidgets('insert an overview block widget', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(
        name: 'workspace_overview_test',
        layout: ViewLayoutPB.Document,
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertWorkspaceOverviewInDocument(tester);

      // validate the overview is inserted
      expect(find.byType(OverviewBlockWidget), findsOneWidget);
    });

    testWidgets('workspace folder to overview block test', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.editor.tapLineOfEditorAt(0);
      await insertWorkspaceOverviewInDocument(tester);

      // validate the outline is inserted
      expect(find.byType(OverviewBlockWidget), findsOneWidget);

      await tester.createNewPageWithNameUnderParent(
        name: firstLevelParentViewName,
        layout: ViewLayoutPB.Document,
      );

      // inserting nested view pages inside `firstLevelParentView`
      final names = [1, 2].map((e) => 'Document View $e').toList();
      for (var i = 0; i < names.length; i++) {
        await tester.createNewPageWithNameUnderParent(
          name: names[i],
          parentName: firstLevelParentViewName,
          layout: ViewLayoutPB.Document,
        );
      }

      // inserting views
      final viewNames = [2, 3].map((e) => 'View $e').toList();
      for (var i = 0; i < viewNames.length; i++) {
        await tester.createNewPageWithNameUnderParent(
          name: viewNames[i],
          parentName: gettingStarted,
          layout: ViewLayoutPB.Document,
        );
      }

      await tester.openPage(gettingStarted);

      for (final name in names) {
        expect(
          find.descendant(
            of: find.byType(OverviewBlockWidget),
            matching: find.text(name),
          ),
          findsOneWidget,
        );
      }

      for (final viewName in viewNames) {
        expect(
          find.descendant(
            of: find.byType(OverviewBlockWidget),
            matching: find.text(viewName),
          ),
          findsOneWidget,
        );
      }

      // deletes the first-level child of the 'Getting Started' page.
      await tester.hoverOnPageName(viewNames[viewNames.length - 1]);
      await tester.tapDeletePageButton();

      // deletes the first-level child of the 'Getting Started' page's child view
      await tester.hoverOnPageName(names[names.length - 1]);
      await tester.tapDeletePageButton();

      // checks whether the deleted views were not visible in the overview block
      expect(
        find.descendant(
          of: find.byType(OverviewBlockWidget),
          matching: find.text(viewNames[viewNames.length - 1]),
        ),
        findsNothing,
      );

      expect(
        find.descendant(
          of: find.byType(OverviewBlockWidget),
          matching: find.text(names[names.length - 1]),
        ),
        findsNothing,
      );

      await tester.hoverOnPageName(firstLevelParentViewName);
      await tester.renamePage('View 1');
    });
  });
}

/// Inserts an workspace overview block in the document
Future<void> insertWorkspaceOverviewInDocument(WidgetTester tester) async {
  // open the actions menu and insert the overview block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_selectionMenu_overview.tr(),
  );
  await tester.pumpAndSettle();
}
