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
      final iconKey = GlobalKey();
      var hit = false;
      final item = ToolbarItem(
        id: 'appflowy.toolbar.test',
        type: 1,
        iconBuilder: (isHighlight) {
          return Icon(
            key: iconKey,
            Icons.abc,
            color: isHighlight ? Colors.lightBlue : null,
          );
        },
        validator: (editorState) => true,
        handler: (editorState, context) {},
        highlightCallback: (editorState) {
          return true;
        },
      );
      final widget = ToolbarItemWidget(
        key: key,
        item: item,
        isHighlight: true,
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
      expect(find.byKey(iconKey), findsOneWidget);
      expect(
        (tester.firstWidget(find.byKey(iconKey)) as Icon).color,
        Colors.lightBlue,
      );

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(hit, true);
    });
  });
}
