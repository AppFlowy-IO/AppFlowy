import 'dart:core';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/overview/workspace_overview_block_component.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String firstLevelParentViewName = 'Overview Test';
  const emoji = '😁';

  group("Doc workspace overview block test: ", () {
    testWidgets('insert an overview block widget', (tester) async {
      await initializeEditorAndInsertOverviewBlock(tester);

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

    testWidgets('updating parent view item of overview block component',
        (tester) async {
      const String viewName = '$gettingStarted View';
      await initializeEditorAndInsertOverviewBlock(tester);

      await tester.hoverOnPageName(gettingStarted);
      await tester.renamePage(viewName);
      await tester.pumpAndSettle();

      // expect parent view name to be updated
      expect(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find.text(viewName),
        ),
        findsOne,
      );

      await tester.updatePageIconInSidebarByName(
        name: viewName,
        parentName: viewName,
        layout: ViewLayoutPB.Document,
        icon: emoji,
      );
      await tester.pumpAndSettle();

      // expect parent view icon to be updated
      expect(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find.text(emoji, findRichText: true),
        ),
        findsOne,
      );
    });

    testWidgets(
      'overview block test',
      (tester) async {
        await initializeEditorAndInsertOverviewBlock(tester);
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

        // navigating to `Getting Started` doc page
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

        await tester.updatePageIconInSidebarByName(
          name: gettingStarted,
          parentName: gettingStarted,
          layout: ViewLayoutPB.Document,
          icon: emoji,
        );

        expect(
          find.descendant(
            of: find.byType(WorkspaceOverviewBlockWidget),
            matching: find.text(emoji, findRichText: true),
          ),
          findsOne,
        );
      },
    );

    testWidgets('overview block expansion test', (tester) async {
      await initializeEditorAndInsertOverviewBlock(tester);

      /// validate the [WorkspaceOverviewBlockWidget] component is inserted
      expect(find.byType(WorkspaceOverviewBlockWidget), findsOneWidget);

      // expect to find [WorkspaceOverviewBlockWidget] expanded
      expect(find.byType(OverviewItemWidget).hitTestable(), findsOneWidget);

      await tester.tapButton(
        find.byKey(
          const Key("OverviewBlockExpansionIcon"),
        ),
      );
      await tester.pumpAndSettle();

      // expect to find [WorkspaceOverviewBlockWidget] collapsed
      expect(find.byType(OverviewItemWidget).hitTestable(), findsNothing);
    });

    testWidgets('navigating to the selected page view item from overview block',
        (tester) async {
      await initializeEditorAndInsertOverviewBlock(tester);

      /// validate the [WorkspaceOverviewBlockWidget] component is inserted
      expect(find.byType(WorkspaceOverviewBlockWidget), findsOneWidget);

      /// inserting views under the `Getting Started` doc page
      final views = [1, 2].map((e) => 'Document View $e').toList();
      await buildViewItems(tester, views);

      // navigating to `Getting Started` doc page
      await tester.openPage(gettingStarted);

      // navigating to `Document View 1` doc page
      await tester.tap(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find.text(views[0]),
        ),
      );
      await tester.pumpAndSettle();

      // expected to be at `Document View 1` doc page
      expect(
        find.descendant(
          of: find.byType(HomeTopBar),
          matching: find.text(views[0]),
        ),
        findsOne,
      );

      // navigating to `Getting Started` doc page
      await tester.openPage(gettingStarted);

      // navigating to `Document View 2` doc page
      await tester.tap(
        find.descendant(
          of: find.byType(WorkspaceOverviewBlockWidget),
          matching: find.text(views[1]),
        ),
      );
      await tester.pumpAndSettle();

      // navigating to `Document View 2` doc page
      expect(
        find.descendant(
          of: find.byType(HomeTopBar),
          matching: find.text(views[1]),
        ),
        findsOne,
      );
    });
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

Future<void> initializeEditorAndInsertOverviewBlock(WidgetTester tester) async {
  await tester.initializeAppFlowy();
  await tester.tapGoButton();

  await tester.editor.tapLineOfEditorAt(0);
  await insertWorkspaceOverviewInDocument(tester);

  await tester.pumpAndSettle();
}
