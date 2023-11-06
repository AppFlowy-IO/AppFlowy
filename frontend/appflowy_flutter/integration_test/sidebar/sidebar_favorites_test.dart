import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/base.dart';
import '../util/common_operations.dart';
import '../util/expectation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Favorites', () {
    testWidgets(
        'Toggle favorites for views creates / removes the favorite header along with favorite views',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // no favorite folder
      expect(find.byType(FavoriteFolder), findsNothing);

      // create the nested views
      final names = [
        1,
        2,
      ].map((e) => 'document_$e').toList();
      for (var i = 0; i < names.length; i++) {
        final parentName = i == 0 ? gettingStarted : names[i - 1];
        await tester.createNewPageWithName(
          name: names[i],
          parentName: parentName,
          layout: ViewLayoutPB.Document,
        );
        tester.expectToSeePageName(
          names[i],
          parentName: parentName,
          layout: ViewLayoutPB.Document,
          parentLayout: ViewLayoutPB.Document,
        );
      }

      await tester.favoriteViewByName(gettingStarted);
      expect(
        tester.findFavoritePageName(gettingStarted),
        findsOneWidget,
      );

      await tester.favoriteViewByName(names[1]);
      expect(
        tester.findFavoritePageName(names[1]),
        findsNWidgets(1),
      );

      await tester.unfavoriteViewByName(gettingStarted);
      expect(
        tester.findFavoritePageName(gettingStarted),
        findsNothing,
      );
      expect(
        tester.findFavoritePageName(
          names[1],
        ),
        findsOneWidget,
      );

      await tester.unfavoriteViewByName(names[1]);
      expect(
        tester.findFavoritePageName(
          names[1],
        ),
        findsNothing,
      );
    });

    testWidgets(
      'renaming a favorite view updates name under favorite header',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        const name = 'test';
        await tester.favoriteViewByName(gettingStarted);
        await tester.hoverOnPageName(
          gettingStarted,
          layout: ViewLayoutPB.Document,
          onHover: () async {
            await tester.renamePage(name);
            await tester.pumpAndSettle();
          },
        );
        expect(
          tester.findPageName(name),
          findsNWidgets(2),
        );
        expect(
          tester.findFavoritePageName(name),
          findsNothing,
        );
      },
    );

    testWidgets(
      'deleting first level favorite view removes its instance from favorite header, deleting root level views leads to removal of all favorites that are its children',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        final names = [1, 2].map((e) => 'document_$e').toList();
        for (var i = 0; i < names.length; i++) {
          final parentName = i == 0 ? gettingStarted : names[i - 1];
          await tester.createNewPageWithName(
            name: names[i],
            parentName: parentName,
            layout: ViewLayoutPB.Document,
          );
          tester.expectToSeePageName(names[i], parentName: parentName);
        }
        await tester.favoriteViewByName(gettingStarted);
        await tester.favoriteViewByName(names[0]);
        await tester.favoriteViewByName(names[1]);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.categoryType == FolderCategoryType.favorite,
          ),
          findsNWidgets(3),
        );

        await tester.hoverOnPageName(
          names[1],
          layout: ViewLayoutPB.Document,
          onHover: () async {
            await tester.tapDeletePageButton();
            await tester.pumpAndSettle();
          },
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.categoryType == FolderCategoryType.favorite,
          ),
          findsNWidgets(2),
        );

        await tester.hoverOnPageName(
          gettingStarted,
          layout: ViewLayoutPB.Document,
          onHover: () async {
            await tester.tapDeletePageButton();
            await tester.pumpAndSettle();
          },
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.categoryType == FolderCategoryType.favorite,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'view selection is synced between favorites and personal folder',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        await tester.createNewPageWithName();
        await tester.favoriteViewByName(gettingStarted);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is FlowyHover &&
                widget.isSelected != null &&
                widget.isSelected!(),
          ),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'context menu opens up for favorites',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        await tester.createNewPageWithName();
        await tester.favoriteViewByName(gettingStarted);
        await tester.hoverOnPageName(
          gettingStarted,
          layout: ViewLayoutPB.Document,
          useLast: false,
          onHover: () async {
            await tester.tapPageOptionButton();
            await tester.pumpAndSettle();
            expect(
              find.byType(PopoverContainer),
              findsOneWidget,
            );
          },
        );
        await tester.pumpAndSettle();
      },
    );
  });
}
