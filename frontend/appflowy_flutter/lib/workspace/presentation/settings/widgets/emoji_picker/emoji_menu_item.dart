import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SelectionMenuItem emojiMenuItem = SelectionMenuItem(
  name: 'Emoji',
  icon: (editorState, onSelected, style) => SelectableIconWidget(
    icon: Icons.emoji_emotions_outlined,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['emoji'],
  handler: (editorState, menuService, context) {
    final container = Overlay.of(context);
    showEmojiPickerMenu(
      container,
      editorState,
      menuService,
    );
  },
);

void showEmojiPickerMenu(
  OverlayState container,
  EditorState editorState,
  SelectionMenuService menuService,
) {
  menuService.dismiss();

  final alignment = menuService.alignment;
  final offset = menuService.offset;
  final top = alignment == Alignment.topLeft ? offset.dy : null;
  final bottom = alignment == Alignment.bottomLeft ? offset.dy : null;

  keepEditorFocusNotifier.increase();
  final emojiPickerMenuEntry = FullScreenOverlayEntry(
    top: top,
    bottom: bottom,
    left: offset.dx,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) => Material(
      type: MaterialType.transparency,
      child: Container(
        width: 300,
        height: 250,
        padding: const EdgeInsets.all(4.0),
        decoration: FlowyDecoration.decoration(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.shadow,
        ),
        child: EmojiSelectionMenu(
          onSubmitted: (emoji) {
            editorState.insertTextAtCurrentSelection(emoji);
          },
          onExit: () {
            // close emoji panel
          },
        ),
      ),
    ),
  ).build();
  container.insert(emojiPickerMenuEntry);
}

class EmojiSelectionMenu extends StatefulWidget {
  const EmojiSelectionMenu({
    Key? key,
    required this.onSubmitted,
    required this.onExit,
  }) : super(key: key);

  final void Function(String emoji) onSubmitted;
  final void Function() onExit;

  @override
  State<EmojiSelectionMenu> createState() => _EmojiSelectionMenuState();
}

class _EmojiSelectionMenuState extends State<EmojiSelectionMenu> {
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
    return FlowyEmojiPicker(
      onEmojiSelected: (_, emoji) {
        widget.onSubmitted(emoji);
      },
    );
  }
}
