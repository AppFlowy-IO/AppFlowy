import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_favorite.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/base.dart';
import 'util/common_operations.dart';

const _readmeName = 'Read me';
const _calendarName = 'Calendar';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Favorites', () {
    testWidgets(
        'Toggle favorites for views creates / removes the favorite header along with favorite views',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(
        find.byType(
          FavoriteHeader,
          skipOffstage: false,
        ),
        findsNothing,
      );

      await tester.createNewPageWithName(
          name: _calendarName, layout: ViewLayoutPB.Calendar);
      await tester.favoriteViewByName(_calendarName);

      expect(
        find.byType(
          FavoriteHeader,
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.expandFavorites();

      expect(
        find.descendant(
          of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
          matching: find.text(_calendarName),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.favoriteViewByName(_readmeName);

      expect(
        find.descendant(
          of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
          matching: find.text(_readmeName),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
          matching: find.byType(ViewSectionItem),
          skipOffstage: false,
        ),
        findsNWidgets(2),
      );
      await tester.unfavoriteViewsByName(_readmeName);
      await tester.unfavoriteViewsByName(_calendarName);

      expect(
        find.byType(
          FavoriteHeader,
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'renaming a favorite view updates name under favorite header',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        expect(
          find.byType(
            FavoriteHeader,
            skipOffstage: false,
          ),
          findsNothing,
        );

        await tester.favoriteViewByName(_readmeName);

        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.findTextInFlowyText(_readmeName),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        await tester.hoverOnPageName(_readmeName);
        await tester.renamePage("Test1");
        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.text("Test1"),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'deleting first level favorite view removes its instance from favorite header, deleting root level views leads to removal of all favorites that are its children',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        expect(
          find.byType(
            FavoriteHeader,
            skipOffstage: false,
          ),
          findsNothing,
        );

        await tester.createNewPageWithName(
          layout: ViewLayoutPB.Calendar,
          name: _calendarName,
        );
        await tester.favoriteViewByName(_calendarName);
        await tester.favoriteViewByName(_readmeName);

        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.byType(ViewSectionItem),
            skipOffstage: false,
          ),
          findsNWidgets(2),
        );
        await tester.hoverOnPageName(_readmeName);
        await tester.tapDeletePageButton();

        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.byType(ViewSectionItem),
            skipOffstage: false,
          ),
          findsOneWidget,
        );

        await tester.openTrashAndRestoreAll();

        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.byType(ViewSectionItem),
            skipOffstage: false,
          ),
          findsOneWidget,
        );

        await tester.openContextMenuOnRootView('⭐️ Getting started');
        await tester.tapButtonWithName(ViewDisclosureAction.delete.name());
        await tester.pumpAndSettle();

        expect(
          find.byType(
            FavoriteHeader,
            skipOffstage: false,
          ),
          findsNothing,
        );

        await tester.openTrashAndRestoreAll();

        expect(
          find.descendant(
            of: find.byType(BlocBuilder<FavoriteBloc, FavoriteState>),
            matching: find.byType(ViewSectionItem),
            skipOffstage: false,
          ),
          findsNothing,
        );
      },
    );
  });
}
