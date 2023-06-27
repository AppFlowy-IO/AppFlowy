import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class EmojiPopover extends StatefulWidget {
  final EditorState editorState;
  final Node node;
  final void Function(Emoji emoji) onEmojiChanged;
  final VoidCallback removeIcon;
  final bool showRemoveButton;

  const EmojiPopover({
    super.key,
    required this.editorState,
    required this.node,
    required this.onEmojiChanged,
    required this.removeIcon,
    required this.showRemoveButton,
  });

  @override
  State<EmojiPopover> createState() => _EmojiPopoverState();
}

class _EmojiPopoverState extends State<EmojiPopover> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showRemoveButton)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: DeleteButton(onTap: widget.removeIcon),
            ),
          ),
        Expanded(
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              widget.onEmojiChanged(emoji);
            },
            config: Config(
              columns: 8,
              emojiSizeMax: 28,
              bgColor: Colors.transparent,
              iconColor: Theme.of(context).iconTheme.color!,
              iconColorSelected: Theme.of(context).colorScheme.onSurface,
              selectedHoverColor: Theme.of(context).colorScheme.secondary,
              progressIndicatorColor: Theme.of(context).iconTheme.color!,
              buttonMode: ButtonMode.CUPERTINO,
              initCategory: Category.RECENT,
            ),
          ),
        ),
      ],
    );
  }
}

class DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const DeleteButton({required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FlowyButton(
        onTap: onTap,
        useIntrinsicWidth: true,
        text: FlowyText(
          LocaleKeys.document_plugins_cover_removeIcon.tr(),
        ),
        leftIcon: const FlowySvg(name: 'editor/delete'),
      ),
    );
  }
}
