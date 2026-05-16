import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar expand test', () {
    bool isExpanded({required FolderSpaceType type}) {
      if (type == FolderSpaceType.private) {
        return find
            .descendant(
              of: find.byType(PrivateSectionFolder),
              matching: find.byType(ViewItem),
            )
            .evaluate()
            .isNotEmpty;
      }
      return false;
    }

    testWidgets('first time the personal folder is expanded', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // first time is expanded
      expect(isExpanded(type: FolderSpaceType.private), true);

      // collapse the personal folder
      await tester.tapButton(
        find.byTooltip(LocaleKeys.sideBar_clickToHidePrivate.tr()),
      );
      expect(isExpanded(type: FolderSpaceType.private), false);

      // expand the personal folder
      await tester.tapButton(
        find.byTooltip(LocaleKeys.sideBar_clickToHidePrivate.tr()),
      );
      expect(isExpanded(type: FolderSpaceType.private), true);
    });

    testWidgets('Expanding with subpage', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      const page1 = 'SubPageBloc', page2 = '$page1 2';
      await tester.createNewPageWithNameUnderParent(name: page1);
      await tester.createNewPageWithNameUnderParent(
        name: page2,
        parentName: page1,
      );

      await tester.expandOrCollapsePage(
        pageName: gettingStarted,
        layout: ViewLayoutPB.Document,
      );

      await tester.tapNewPageButton();

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();
      await tester.editor.showSlashMenu();
      await tester.pumpAndSettle();

      final slashMenu = find
          .ancestor(
            of: find.byType(SelectionMenuItemWidget),
            matching: find.byWidgetPredicate(
              (widget) => widget is Scrollable,
            ),
          )
          .first;
      final slashMenuItem = find.text(
        LocaleKeys.document_slashMenu_name_linkedDoc.tr(),
      );
      await tester.scrollUntilVisible(
        slashMenuItem,
        100,
        scrollable: slashMenu,
        duration: const Duration(milliseconds: 250),
      );

      final menuItemFinder = find.byWidgetPredicate(
        (w) =>
            w is SelectionMenuItemWidget &&
            w.item.name == LocaleKeys.document_slashMenu_name_linkedDoc.tr(),
      );

      final menuItem =
          menuItemFinder.evaluate().first.widget as SelectionMenuItemWidget;

      /// tapSlashMenuItemWithName is not working, so invoke this function directly
      menuItem.item.handler(
        menuItem.editorState,
        menuItem.menuService,
        menuItemFinder.evaluate().first,
      );

      await tester.pumpAndSettle();
      final actionHandler = find.byType(InlineActionsHandler);
      final subPage = find.descendant(
        of: actionHandler,
        matching: find.text(page2, findRichText: true),
      );
      await tester.tapButton(subPage);

      final subpageBlock = find.descendant(
        of: find.byType(AppFlowyEditor),
        matching: find.text(page2, findRichText: true),
      );

      expect(find.text(page2, findRichText: true), findsOneWidget);
      await tester.tapButton(subpageBlock);

      /// one is in SectionFolder, another one is in CoverTitle
      /// the last one is in FlowyNavigation
      expect(find.text(page2, findRichText: true), findsNWidgets(3));
    });
  });
}
