import 'package:appflowy/mobile/presentation/inline_actions/mobile_inline_actions_menu.dart';
import 'package:appflowy/mobile/presentation/inline_actions/mobile_inline_actions_menu_group.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const title = 'Test At Menu';

  group('at menu', () {
    testWidgets('show at menu', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createPageAndShowAtMenu(title);
      final menuWidget = find.byType(MobileInlineActionsMenu);
      expect(menuWidget, findsOneWidget);
    });

    testWidgets('search by at menu', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createPageAndShowAtMenu(title);
      const searchText = gettingStarted;
      await tester.ime.insertText(searchText);
      final actionWidgets = find.byType(MobileInlineActionsWidget);
      expect(actionWidgets, findsNWidgets(2));
    });

    testWidgets('tap at menu', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createPageAndShowAtMenu(title);
      const searchText = gettingStarted;
      await tester.ime.insertText(searchText);
      final actionWidgets = find.byType(MobileInlineActionsWidget);
      await tester.tap(actionWidgets.last);
      expect(find.byType(MentionPageBlock), findsOneWidget);
    });
  });
}
