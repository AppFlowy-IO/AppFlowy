import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emoji_picker.dart';

SelectionMenuItem emojiMenuItem = SelectionMenuItem(
  name: () => 'Emoji',
  icon: (editorState, onSelected) => Icon(
    Icons.emoji_emotions_outlined,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['emoji'],
  handler: _showEmojiSelectionMenu,
);

OverlayEntry? _emojiSelectionMenu;
EditorState? _editorState;
void _showEmojiSelectionMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
) {
  final aligment = menuService.alignment;
  final offset = menuService.offset;
  menuService.dismiss();

  _emojiSelectionMenu?.remove();
  _emojiSelectionMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: aligment == Alignment.bottomLeft ? offset.dy : null,
      bottom: aligment == Alignment.topLeft ? offset.dy : null,
      left: offset.dx,
      child: Material(
        child: EmojiSelectionMenu(
          editorState: editorState,
          onSubmitted: (text) {
            // insert emoji
            editorState.insertEmoji(text);
          },
          onExit: () {
            _dismissEmojiSelectionMenu();
            //close emoji panel
          },
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_emojiSelectionMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(_dismissEmojiSelectionMenu);
}

void _dismissEmojiSelectionMenu() {
  _emojiSelectionMenu?.remove();
  _emojiSelectionMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissEmojiSelectionMenu);
  _editorState = null;
}

class EmojiSelectionMenu extends StatefulWidget {
  const EmojiSelectionMenu({
    Key? key,
    required this.onSubmitted,
    required this.onExit,
    required this.editorState,
  }) : super(key: key);

  final void Function(Emoji emoji) onSubmitted;
  final void Function() onExit;
  final EditorState editorState;

  @override
  State<EmojiSelectionMenu> createState() => _EmojiSelectionMenuState();
}

class _EmojiSelectionMenuState extends State<EmojiSelectionMenu> {
  EditorStyle get style => widget.editorState.editorStyle;

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
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: style.selectionMenuBackgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: _buildEmojiBox(context),
    );
  }

  Widget _buildEmojiBox(BuildContext context) {
    return SizedBox(
      height: 200,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => widget.onSubmitted(emoji),
        config: Config(
          columns: 8,
          emojiSizeMax: 28,
          bgColor:
              style.selectionMenuBackgroundColor ?? const Color(0xffF2F2F2),
          iconColor: Colors.grey,
          iconColorSelected: const Color(0xff333333),
          indicatorColor: const Color(0xff333333),
          progressIndicatorColor: const Color(0xff333333),
          buttonMode: ButtonMode.CUPERTINO,
          initCategory: Category.RECENT,
        ),
      ),
    );
  }
}

extension on EditorState {
  void insertEmoji(Emoji emoji) {
    final selectionService = service.selectionService;
    final currentSelection = selectionService.currentSelection.value;
    final nodes = selectionService.currentSelectedNodes;
    if (currentSelection == null ||
        !currentSelection.isCollapsed ||
        nodes.first is! TextNode) {
      return;
    }
    final textNode = nodes.first as TextNode;
    final tr = transaction;
    tr.insertText(
      textNode,
      currentSelection.endIndex,
      emoji.emoji,
    );
    apply(tr);
  }
}
