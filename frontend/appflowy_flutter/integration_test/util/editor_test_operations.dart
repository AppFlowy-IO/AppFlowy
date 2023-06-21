import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:flutter_test/flutter_test.dart';

import 'ime.dart';
import 'util.dart';

extension EditorWidgetTester on WidgetTester {
  EditorOperations get editor => EditorOperations(this);
}

class EditorOperations {
  const EditorOperations(this.tester);

  final WidgetTester tester;

  EditorState getCurrentEditorState() {
    return tester
        .widget<AppFlowyEditor>(find.byType(AppFlowyEditor))
        .editorState;
  }

  /// Tap the line of editor at [index]
  Future<void> tapLineOfEditorAt(int index) async {
    final textBlocks = find.byType(TextBlockComponentWidget);
    await tester.tapAt(tester.getTopRight(textBlocks.at(index)));
  }

  /// Hover on cover plugin button above the document
  Future<void> hoverOnCoverPluginAddButton() async {
    final editor = find.byWidgetPredicate(
      (widget) => widget is AppFlowyEditor,
    );
    await tester.hoverOnWidget(
      editor,
      offset: tester.getTopLeft(editor).translate(20, 20),
    );
  }

  /// trigger the slash command (selection menu)
  Future<void> showSlashMenu() async {
    await tester.ime.insertCharacter('/');
  }

  /// Tap the slash menu item with [name]
  ///
  /// Must call [showSlashMenu] first.
  Future<void> tapSlashMenuItemWithName(String name) async {
    final slashMenuItem = find.text(name, findRichText: true);
    await tester.tapButton(slashMenuItem);
  }
}
