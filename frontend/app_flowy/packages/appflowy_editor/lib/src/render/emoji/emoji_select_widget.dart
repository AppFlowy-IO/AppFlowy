import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/render/style/editor_style.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/presentation/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:app_flowy/workspace/presentation/widgets/emoji_picker/src/config.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' as foundation;

OverlayEntry? _imojiSelectionMenu;
EditorState? _editorState;
void showEmojiSelectionMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
) {
  menuService.dismiss();

  _imojiSelectionMenu?.remove();
  _imojiSelectionMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: menuService.topLeft.dy,
      left: menuService.topLeft.dx,
      child: Material(
        child: EmojiSelectionMenu(
          editorState: editorState,
          onSubmitted: (text) {
            // insert emoji
            editorState.insertEmojiNode(text);
          },
          onExit: () {
            _dismissEmojiSelectionMenu();
            //close emoji panel
          },
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_imojiSelectionMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(_dismissEmojiSelectionMenu);
}

void _dismissEmojiSelectionMenu() {
  _imojiSelectionMenu?.remove();
  _imojiSelectionMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissEmojiSelectionMenu);
  _editorState = null;
}

class EmojiSelectionMenu extends StatefulWidget {
  const EmojiSelectionMenu({
    Key? key,
    required this.onSubmitted,
    required this.onExit,
    this.editorState,
  }) : super(key: key);

  final void Function(String Emoji) onSubmitted;
  final void Function() onExit;
  final EditorState? editorState;

  @override
  State<EmojiSelectionMenu> createState() => _EmojiSelectionMenuState();
}

class _EmojiSelectionMenuState extends State<EmojiSelectionMenu> {
  EditorStyle? get style => widget.editorState?.editorStyle;

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    super.initState();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      //triggers on esc
      widget.onExit();
      return true;
    } else {
      return false;
    }
  }

  @override
  void deactivate() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: style?.selectionMenuBackgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        // borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10.0),
          _buildEmojiBox(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      LocaleKeys.settings_menu_language.tr(),
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 14.0,
        color: style?.selectionMenuItemTextColor ?? Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmojiBox(BuildContext context) {
    return SizedBox(
      height: 300,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => widget.onSubmitted(emoji.emoji),
        config: Config(
          columns: 8,
          emojiSizeMax: 28,
          bgColor: Color(0xffF2F2F2),
          iconColor: Colors.grey,
          iconColorSelected: Color(0xff333333),
          indicatorColor: Color(0xff333333),
          progressIndicatorColor: Color(0xff333333),
          buttonMode: ButtonMode.CUPERTINO,
          initCategory: Category.RECENT,
        ),
      ),
    );
  }
}

extension on EditorState {
  void insertEmojiNode(String emoji) {
    final selection = service.selectionService.currentSelection.value;
    final textNodes =
        service.selectionService.currentSelectedNodes.whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    // final transaction = this.transaction;
    // transaction.insertNode(
    //   selection.end.path,
    //   TextNode(
    //     delta: Delta()..insert(emoji),
    //   ),
    // );
    // apply(transaction);

    final selectionService = service.selectionService;
    final currentSelection = selectionService.currentSelection.value;

    if (currentSelection == null) {
      return;
    }

    final textNode = selectionService.currentSelectedNodes.first as TextNode;
    final transaction = this.transaction;
    transaction.insertText(textNode, currentSelection.endIndex, emoji);
    apply(transaction);
  }
}
