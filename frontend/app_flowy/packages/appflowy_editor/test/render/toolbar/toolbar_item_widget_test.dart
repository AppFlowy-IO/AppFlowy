import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('toolbar_item_widget.dart', () {
    testWidgets('test single toolbar item widget', (tester) async {
      final key = GlobalKey();
      var hit = false;
      final item = ToolbarItem(
        id: 'appflowy.toolbar.test',
        type: 1,
        icon: const Icon(Icons.abc),
        validator: (editorState) => true,
        handler: (editorState, context) {},
      );
      final widget = ToolbarItemWidget(
        key: key,
        item: item,
        onPressed: (() {
          hit = true;
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: widget,
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(hit, true);
    });
  });
}
