
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emoji_picker.dart';

SelectionMenuItem emojiMenuItem = 
  SelectionMenuItem(
    name: () => 'emoji',
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
      top: aligment == Alignment.bottomRight ? offset.dy : null,
      bottom:
            aligment == Alignment.topRight ? offset.dy : null,
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
    this.editorState,
  }) : super(key: key);

  final void Function(Emoji emoji) onSubmitted;
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
          // FlowyEmojiStyleButton(normalIcon: '', tooltipText: ''),
          const SizedBox(height: 10.0),
          _buildEmojiBox(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Pick Emoji',
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
        onEmojiSelected: (category, emoji) => widget.onSubmitted(emoji),
        config: const Config(
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
  void insertEmoji(Emoji emoji) {
    final selectionService = service.selectionService;
    final currentSelection = selectionService.currentSelection.value;
    final nodes = selectionService.currentSelectedNodes;
    if (currentSelection == null || !currentSelection.isCollapsed || nodes.first is! TextNode) {
      return;
    }
    final textNode = nodes.first as TextNode;
    final tr = transaction;
    tr.insertText(textNode, currentSelection.endIndex, emoji.emoji,);
    apply(tr);
  }
}
