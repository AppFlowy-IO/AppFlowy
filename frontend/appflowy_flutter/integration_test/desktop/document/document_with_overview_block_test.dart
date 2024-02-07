import 'dart:core';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/overview/workspace_overview_block_component.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/util.dart';

void main() {
  const String firstLevelParentViewName = 'Overview Test';

  group("Doc workspace overview block test: ", () {
    testWidgets('insert an overview block widget', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.editor.tapLineOfEditorAt(0);
      await insertWorkspaceOverviewInDocument(tester);

      /// validate the [WorkspaceOverviewBlockWidget] component is inserted
      expect(find.byType(WorkspaceOverviewBlockWidget), findsOneWidget);

      // expect to find "Workspace Overview" title placeholder under the [WorkspaceOverviewBlockWidget] component
      expect(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find
              .text(LocaleKeys.document_selectionMenu_workspaceOverview.tr()),
        ),
        findsOneWidget,
      );

      /// expect to find `Getting Started` view name under the [WorkspaceOverviewBlockWidget] component
      expect(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find.text(gettingStarted),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'view actions to overview block test',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        await tester.editor.tapLineOfEditorAt(0);
        await insertWorkspaceOverviewInDocument(tester);

        // validate the overview is inserted
        expect(find.byType(WorkspaceOverviewBlockWidget), findsOneWidget);

        await tester.createNewPageWithNameUnderParent(
          name: firstLevelParentViewName,
        );

        /// inserting nested view pages under the [firstLevelParentView] of `Getting Started` doc page
        final viewsUnderFirstLvlParent =
            [1, 2].map((e) => 'Document View $e').toList();
        await buildViewItems(
          tester,
          viewsUnderFirstLvlParent,
          parentName: firstLevelParentViewName,
        );

        /// inserting views under the `Getting Started` doc page
        final firstLevelViewNames =
            [2, 3].map((e) => 'Sub-Doc View $e').toList();
        await buildViewItems(tester, firstLevelViewNames);

        await tester.openPage(gettingStarted);

        /// expect all views to be present under the first-level parent view of `Getting Started` doc page
        checkOverviewBlockComponentChildItems(tester, viewsUnderFirstLvlParent);

        /// expect all views to be present under the `Getting Started` doc page
        checkOverviewBlockComponentChildItems(tester, firstLevelViewNames);

        /// deletes the first-level child of the `Getting Started` page
        await tester.hoverOnPageName(
          firstLevelViewNames[firstLevelViewNames.length - 1],
        );
        await tester.tapDeletePageButton();

        /// deletes the first-level child of the `Getting Started` page's child view
        await tester.hoverOnPageName(
          viewsUnderFirstLvlParent[viewsUnderFirstLvlParent.length - 1],
        );
        await tester.tapDeletePageButton();

        // checks whether the deleted views were not visible in the overview block
        expect(
          find.descendant(
            of: find.byType(WorkspaceOverviewBlockWidget),
            matching:
                find.text(firstLevelViewNames[firstLevelViewNames.length - 1]),
          ),
          findsNothing,
        );

        expect(
          find.descendant(
            of: find.byType(WorkspaceOverviewBlockWidget),
            matching: find.text(
              viewsUnderFirstLvlParent[viewsUnderFirstLvlParent.length - 1],
            ),
          ),
          findsNothing,
        );

        await tester.hoverOnPageName(firstLevelParentViewName);
        await tester.renamePage('View 1');

        // expect the name of the first-level view to be changed
        expect(
          find.descendant(
            of: find.byType(WorkspaceOverviewBlockWidget),
            matching: find.text('View 1'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}

/// Inserts an [WorkspaceOverviewBlockWidget] component in the document page
Future<void> insertWorkspaceOverviewInDocument(WidgetTester tester) async {
  // open the actions menu and insert the overview block component
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_selectionMenu_workspaceOverview.tr(),
  );
  await tester.pumpAndSettle();
}

Future<void> buildViewItems(
  WidgetTester tester,
  List<String> views, {
  String parentName = gettingStarted,
}) async {
  for (final String view in views) {
    await tester.createNewPageWithNameUnderParent(
      name: view,
      parentName: parentName,
    );
  }
}

void checkOverviewBlockComponentChildItems(
  WidgetTester tester,
  List<String> views,
) {
  for (final view in views) {
    expect(
      find.descendant(
        of: find.byType(WorkspaceOverviewBlockWidget),
        matching: find.text(view),
      ),
      findsOneWidget,
    );
  }
}
