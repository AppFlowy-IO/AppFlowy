import 'package:appflowy_editor/src/render/selection_menu/selection_menu_item_widget.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('selection_menu_item_widget.dart', () {
    testWidgets('test selection menu item widget', (tester) async {
      bool flag = false;
      final editorState = tester.editor.editorState;
      final menuService = _TestSelectionMenuService();
      const icon = Icon(Icons.abc);
      final item = SelectionMenuItem(
        name: () => 'example',
        icon: icon,
        keywords: ['example A', 'example B'],
        handler: (editorState, menuService, context) {
          flag = true;
        },
      );
      final widget = SelectionMenuItemWidget(
        editorState: editorState,
        menuService: menuService,
        item: item,
        isSelected: true,
      );
      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.tap(find.byType(SelectionMenuItemWidget));
      expect(flag, true);
    });
  });
}

class _TestSelectionMenuService implements SelectionMenuService {
  @override
  void dismiss() {}

  @override
  void show() {}

  @override
  Offset get topLeft => throw UnimplementedError();
}
