import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board row test', () {
    testWidgets('delete item in ToDo card', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.hoverOnWidget(
        card1,
        onHover: () async {
          final moreOption = find.byType(MoreCardOptionsAccessory);
          await tester.tapButton(moreOption);
        },
      );
      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());
      await tester.tapOKButton();
      expect(find.text(name), findsNothing);
    });

    testWidgets('duplicate item in ToDo card', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);
      const name = 'Card 1';
      final card1 = find.text(name);
      await tester.hoverOnWidget(
        card1,
        onHover: () async {
          final moreOption = find.byType(MoreCardOptionsAccessory);
          await tester.tapButton(moreOption);
        },
      );
      await tester.tapButtonWithName(LocaleKeys.button_duplicate.tr());
      expect(find.textContaining(name, findRichText: true), findsNWidgets(2));
    });
  });
}
