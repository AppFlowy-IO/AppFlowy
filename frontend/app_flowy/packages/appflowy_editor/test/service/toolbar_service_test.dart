import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('toolbar_service.dart', () {
    testWidgets('Test toolbar service in multi text selection', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [1], offset: text.length),
      );
      await editor.updateSelection(selection);

      expect(find.byType(ToolbarWidget), findsOneWidget);

      // no link item
      final item = defaultToolbarItems
          .where((item) => item.id == 'appflowy.toolbar.link')
          .first;
      expect(find.byWidget(item.icon), findsNothing);
    });
  });
}
