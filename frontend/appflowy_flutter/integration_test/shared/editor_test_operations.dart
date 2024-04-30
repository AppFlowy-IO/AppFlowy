import 'dart:async';
import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/base/emoji/emoji_skin_tone.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_add_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_editor.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/document_header_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/embed_image_url_widget.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final textBlocks = find.byType(AppFlowyRichText);
    index = index.clamp(0, textBlocks.evaluate().length - 1);
    await tester.tapAt(tester.getTopRight(textBlocks.at(index)));
    await tester.pumpAndSettle();
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
    expect(find.byType(FlowyEmojiPicker), findsOneWidget);
  }

  Future<void> tapGettingStartedIcon() async {
    await tester.tapButton(
      find.descendant(
        of: find.byType(DocumentCoverWidget),
        matching: find.findTextInFlowyText('⭐️'),
      ),
    );
  }

  /// Taps on the 'Skin tone' button
  ///
  /// Must call [tapAddIconButton] first.
  Future<void> changeEmojiSkinTone(EmojiSkinTone skinTone) async {
    await tester.tapButton(
      find.byTooltip(LocaleKeys.emoji_selectSkinTone.tr()),
    );
    final skinToneButton = find.byKey(emojiSkinToneKey(skinTone.icon));
    await tester.tapButton(skinToneButton);
  }

  /// Taps the 'Remove Icon' button in the cover toolbar and the icon popover
  Future<void> tapRemoveIconButton({bool isInPicker = false}) async {
    Finder button =
        find.text(LocaleKeys.document_plugins_cover_removeIcon.tr());
    if (isInPicker) {
      button = find.descendant(
        of: find.byType(FlowyIconPicker),
        matching: button,
      );
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
      (widget) => widget is ColorItem && widget.option.name == 'Purple',
    );
    await tester.tapButton(findPurpleButton);
  }

  Future<void> addNetworkImageCover(String imageUrl) async {
    final embedLinkButton = find.findTextInFlowyText(
      LocaleKeys.document_imageBlock_embedLink_label.tr(),
    );
    await tester.tapButton(embedLinkButton);

    final imageUrlTextField = find.descendant(
      of: find.byType(EmbedImageUrlWidget),
      matching: find.byType(TextField),
    );
    await tester.enterText(imageUrlTextField, imageUrl);
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.descendant(
        of: find.byType(EmbedImageUrlWidget),
        matching: find.findTextInFlowyText(
          LocaleKeys.document_imageBlock_embedLink_label.tr(),
        ),
      ),
    );
  }

  Future<void> switchNetworkImageCover(String imageUrl) async {
    final image = find.byWidgetPredicate(
      (widget) => widget is ImageGridItem,
    );
    await tester.tapButton(image);
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

  /// trigger the mention (@) command
  Future<void> showAtMenu() async {
    await tester.ime.insertCharacter('@');
  }

  /// Tap the slash menu item with [name]
  ///
  /// Must call [showSlashMenu] first.
  Future<void> tapSlashMenuItemWithName(String name) async {
    final slashMenuItem = find.text(name, findRichText: true);
    await tester.tapButton(slashMenuItem);
  }

  /// Tap the at menu item with [name]
  ///
  /// Must call [showAtMenu] first.
  Future<void> tapAtMenuItemWithName(String name) async {
    final atMenuItem = find.descendant(
      of: find.byType(InlineActionsHandler),
      matching: find.text(name, findRichText: true),
    );
    await tester.tapButton(atMenuItem);
  }

  /// Update the editor's selection
  Future<void> updateSelection(Selection selection) async {
    final editorState = getCurrentEditorState();
    unawaited(
      editorState.updateSelectionWithReason(
        selection,
        reason: SelectionUpdateReason.uiEvent,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  /// hover and click on the + button beside the block component.
  Future<void> hoverAndClickOptionAddButton(
    Path path,
    bool withModifiedKey, // alt on windows or linux, option on macos
  ) async {
    final optionAddButton = find.byWidgetPredicate(
      (widget) =>
          widget is BlockComponentActionWrapper &&
          widget.node.path.equals(path),
    );
    await tester.hoverOnWidget(
      optionAddButton,
      onHover: () async {
        if (withModifiedKey) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        }
        await tester.tapButton(
          find.byWidgetPredicate(
            (widget) =>
                widget is BlockAddButton &&
                widget.blockComponentContext.node.path.equals(path),
          ),
        );
        if (withModifiedKey) {
          await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        }
      },
    );
  }

  /// hover and click on the option menu button beside the block component.
  Future<void> hoverAndClickOptionMenuButton(Path path) async {
    final optionMenuButton = find.byWidgetPredicate(
      (widget) =>
          widget is BlockComponentActionWrapper &&
          widget.node.path.equals(path),
    );
    await tester.hoverOnWidget(
      optionMenuButton,
      onHover: () async {
        await tester.tapButton(
          find.byWidgetPredicate(
            (widget) =>
                widget is BlockOptionButton &&
                widget.blockComponentContext.node.path.equals(path),
          ),
        );
      },
    );
  }
}
