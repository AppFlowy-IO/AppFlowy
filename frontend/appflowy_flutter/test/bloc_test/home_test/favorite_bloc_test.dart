import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../util.dart';

class FavoriteTestContext {
  late ViewPB view;
  late AppBloc appBloc;
  late List<ViewPB> allViews;
  final AppFlowyUnitTest unitTest;

  FavoriteTestContext(this.unitTest);

  Future<void> initialize() async {
    view = await unitTest.createTestApp();
    appBloc = AppBloc(view: view)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView(
        "Document 1",
        ViewLayoutPB.Document,
      ),
    );
    await blocResponseFuture();

    allViews = [...appBloc.state.view.childViews];
    assert(allViews.length == 1, 'but receive ${allViews.length}');
  }
}

void main() {
  late AppFlowyUnitTest unitTest;
  setUpAll(() async {
    unitTest = await AppFlowyUnitTest.ensureInitialized();
  });

  group('favorites test', () {
    test('toggle favorite status', () async {
      final context = FavoriteTestContext(unitTest);
      await context.initialize();
      final favoriteBloc = FavoriteBloc()..add(const FavoriteEvent.initial());
      await blocResponseFuture(millisecond: 200);

      // try toggling favorite for a view twice and check state
      //favoriting a view
      var viewUnderTest = context.appBloc.state.view.childViews[0];
      favoriteBloc.add(FavoriteEvent.toggle(viewUnderTest));
      await blocResponseFuture(millisecond: 500);
      assert(favoriteBloc.state.objects.length == 1);
      assert(favoriteBloc.state.objects.first.id == viewUnderTest.id);
      assert(favoriteBloc.state.objects.first.isFavorite);

      //unfavoriting the previous view
      viewUnderTest = context.appBloc.state.view.childViews[0];
      favoriteBloc.add(FavoriteEvent.toggle(viewUnderTest));
      await blocResponseFuture(millisecond: 500);
      assert(favoriteBloc.state.objects.isEmpty);
    });
  });
}
