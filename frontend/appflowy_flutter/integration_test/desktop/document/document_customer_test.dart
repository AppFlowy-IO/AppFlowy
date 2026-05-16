import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('customer:', () {
    testWidgets('backtick issue - inline code', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'backtick issue';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.tap(find.byType(AppFlowyEditor));
      // input backtick
      const text = '`Hello` AppFlowy';

      for (var i = 0; i < text.length; i++) {
        await tester.ime.insertCharacter(text[i]);
      }

      final node = tester.editor.getNodeAtPath([0]);
      expect(
        node.delta?.toJson(),
        equals([
          {
            "insert": "Hello",
            "attributes": {"code": true},
          },
          {"insert": " AppFlowy"},
        ]),
      );
    });

    testWidgets('backtick issue - inline code', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'backtick issue';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.tap(find.byType(AppFlowyEditor));
      // input backtick
      const text = '```';

      for (var i = 0; i < text.length; i++) {
        await tester.ime.insertCharacter(text[i]);
      }

      final node = tester.editor.getNodeAtPath([0]);
      expect(node.type, equals(CodeBlockKeys.type));
    });
  });
}
