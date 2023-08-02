import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/base.dart';
import 'util/common_operations.dart';
import 'util/expectation.dart';

const String gettingStated = '⭐️ Getting started';
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Favorites', () {
    testWidgets(
        'Toggle favorites for views creates / removes the favorite header along with favorite views',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ViewItem &&
              widget.view.isFavorite &&
              widget.key.toString().contains('favorite'),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();

      final names = [1, 2, 3, 4].map((e) => 'document_$e').toList();
      for (var i = 0; i < names.length; i++) {
        final parentName = i == 0 ? gettingStated : names[i - 1];
        await tester.createNewPageWithName(
          name: names[i],
          parentName: parentName,
          layout: ViewLayoutPB.Document,
        );
        tester.expectToSeePageName(names[i], parentName: parentName);
      }

      await tester.pumpAndSettle();
      await tester.favoriteViewByName(gettingStated);

      expect(
        tester.findFavoritePageName(
          gettingStated,
        ),
        findsOneWidget,
      );

      await tester.favoriteViewByName(names[3]);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ViewItem &&
              widget.view.isFavorite &&
              widget.key.toString().contains('favorite'),
        ),
        findsNWidgets(3),
      );
      await tester.unfavoriteViewsByName(gettingStated);

      expect(
        tester.findFavoritePageName(
          names[3],
        ),
        findsOneWidget,
      );

      await tester.unfavoriteViewsByName(names[3]);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ViewItem &&
              widget.view.isFavorite &&
              widget.key.toString().contains('favorite'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'renaming a favorite view updates name under favorite header',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        final names = [1, 2].map((e) => 'document_$e').toList();
        for (var i = 0; i < names.length; i++) {
          final parentName = i == 0 ? gettingStated : names[i - 1];
          await tester.createNewPageWithName(
            name: names[i],
            parentName: parentName,
            layout: ViewLayoutPB.Document,
          );
          tester.expectToSeePageName(names[i], parentName: parentName);
        }
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.key.toString().contains('favorite'),
          ),
          findsNothing,
        );

        await tester.pumpAndSettle();
        await tester.favoriteViewByName(gettingStated);

        expect(
          tester.findFavoritePageName(
            gettingStated,
          ),
          findsOneWidget,
        );
        await tester.hoverOnPageName(
          gettingStated,
          layout: ViewLayoutPB.Document,
          onHover: () async {
            await tester.renamePage("test");
            await tester.pumpAndSettle();
          },
        );
        await tester.pumpAndSettle();
        expect(
          tester.findPageName(
            "test",
          ),
          findsNWidgets(2),
        );

        await tester.pumpAndSettle();
        await tester.favoriteViewByName(names[1]);

        await tester.hoverOnPageName(
          names[1],
          layout: ViewLayoutPB.Document,
          onHover: () async {
            await tester.renamePage("test2");
            await tester.pumpAndSettle();
          },
        );
        await tester.pumpAndSettle();

        expect(
          tester.findPageName(
            "test2",
          ),
          findsNWidgets(3),
        );
      },
    );

    testWidgets(
      'deleting first level favorite view removes its instance from favorite header, deleting root level views leads to removal of all favorites that are its children',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.key.toString().contains('favorite'),
          ),
          findsNothing,
        );

        final names = [1, 2].map((e) => 'document_$e').toList();
        for (var i = 0; i < names.length; i++) {
          final parentName = i == 0 ? gettingStated : names[i - 1];
          await tester.createNewPageWithName(
            name: names[i],
            parentName: parentName,
            layout: ViewLayoutPB.Document,
          );
          tester.expectToSeePageName(names[i], parentName: parentName);
        }
        await tester.favoriteViewByName(gettingStated);
        await tester.favoriteViewByName(names[0]);
        await tester.favoriteViewByName(names[1]);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ViewItem &&
                widget.view.isFavorite &&
                widget.key.toString().contains('favorite'),
          ),
          findsNWidgets(6),
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
                widget.key.toString().contains('favorite'),
          ),
          findsNWidgets(3),
        );

        await tester.hoverOnPageName(
          gettingStated,
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
                widget.key.toString().contains('favorite'),
          ),
          findsNothing,
        );
      },
    );
  });
}
