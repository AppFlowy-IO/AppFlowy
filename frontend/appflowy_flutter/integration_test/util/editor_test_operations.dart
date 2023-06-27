import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_editor.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/document_header_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
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
  Future<void> hoverOnCoverToolbar() async {
    final coverToolbar = find.byType(DocumentHeaderToolbar);
    await tester.startGesture(
      tester.getBottomLeft(coverToolbar).translate(5, -5),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
  }

  /// Taps on the 'Add Icon' button in the cover toolbar
  Future<void> tapAddIconButton() async {
    await tester.tapButtonWithName(
      LocaleKeys.document_plugins_cover_addIcon.tr(),
    );
    expect(find.byType(EmojiPopover), findsOneWidget);
  }

  /// Taps the 'Remove Icon' button in the cover toolbar and the icon popover
  Future<void> tapRemoveIconButton({bool isInPicker = false}) async {
    Finder button =
        find.text(LocaleKeys.document_plugins_cover_removeIcon.tr());
    if (isInPicker) {
      button = find.descendant(of: find.byType(EmojiPopover), matching: button);
    }

    await tester.tapButton(button);
  }

  /// Requires that the document must already have an icon. This opens the icon
  /// picker
  Future<void> tapOnIconWidget() async {
    final iconWidget = find.byType(EmojiIconWidget);
    await tester.tapButton(iconWidget);
  }

  Future<void> tapOnAddCover() async {
    await tester.tapButtonWithName(
      LocaleKeys.document_plugins_cover_addCover.tr(),
    );
  }

  Future<void> tapOnChangeCover() async {
    await tester.tapButtonWithName(
      LocaleKeys.document_plugins_cover_changeCover.tr(),
    );
  }

  Future<void> switchSolidColorBackground() async {
    final findPurpleButton = find.byWidgetPredicate(
      (widget) => widget is ColorItem && widget.option.colorHex == "ffe8e0ff",
    );
    await tester.tapButton(findPurpleButton);
  }

  Future<void> tapOnRemoveCover() async {
    await tester.tapButton(find.byType(DeleteCoverButton));
  }

  /// A cover must be present in the document to function properly since this
  /// catches all cover types collectively
  Future<void> hoverOnCover() async {
    final cover = find.byType(DocumentCover);
    await tester.startGesture(
      tester.getCenter(cover),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
  }

  Future<void> dismissCoverPicker() async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
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
