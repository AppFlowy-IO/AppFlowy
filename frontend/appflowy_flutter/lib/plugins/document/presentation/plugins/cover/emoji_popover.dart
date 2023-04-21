import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/src/default_emoji_picker_view.dart';
import 'package:appflowy/workspace/presentation/widgets/emoji_picker/src/emoji_view_state.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
    return Padding(
      padding: const EdgeInsets.all(15),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          widget.onEmojiChanged(emoji);
        },
        customWidget: (Config config, EmojiViewState state) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: EdgeInsets.only(top: widget.showRemoveButton ? 25 : 0),
                child: DefaultEmojiPickerView(config, state),
              ),
              _buildDeleteButtonIfNeed(),
            ],
          );
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
    );
  }

  Widget _buildDeleteButtonIfNeed() {
    if (!widget.showRemoveButton) {
      return const SizedBox();
    }
    return FlowyButton(
      onTap: () => widget.removeIcon(),
      useIntrinsicWidth: true,
      text: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const FlowySvg(name: 'editor/delete'),
          const SizedBox(
            width: 5,
          ),
          FlowyText(
            LocaleKeys.document_plugins_cover_removeIcon.tr(),
          ),
        ],
      ),
    );
  }
}
