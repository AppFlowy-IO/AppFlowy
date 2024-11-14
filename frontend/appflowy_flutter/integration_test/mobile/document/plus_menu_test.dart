import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document plus menu:', () {
    testWidgets('add the toggle heading blocks via plus menu', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createNewDocumentOnMobile('toggle heading blocks');

      final editorState = tester.editor.getCurrentEditorState();
      // focus on the editor
      final selection = Selection.collapsed(Position(path: [0]));
      editorState.selection = selection;
      await tester.pumpAndSettle();

      // click the plus menu button
      final plusMenuButton = find.byKey(addBlockToolbarItemKey);
      final addMenuItem = find.byType(AddBlockMenu);
      await tester.tapButton(plusMenuButton);
      await tester.pumpUntilFound(addMenuItem);

      final toggleHeading1 = find.byWidgetPredicate(
        (widget) =>
            widget is TypeOptionMenuItem &&
            widget.value.text ==
                LocaleKeys.document_slashMenu_name_toggleHeading1.tr(),
      );
      final scrollable = find.ancestor(
        of: find.byType(TypeOptionGridView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        toggleHeading1,
        100,
        scrollable: scrollable,
      );
      await tester.tapButton(toggleHeading1);
      await tester.pumpUntilNotFound(addMenuItem);

      // check the block is inserted
      final block = editorState.getNodeAtPath([1])!;
      expect(block.type, equals(ToggleListBlockKeys.type));
      expect(block.attributes[ToggleListBlockKeys.level], equals(1));
    });
  });
}
