import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_skin_tone.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

typedef EmojiKeywordChangedCallback = void Function(String keyword);
typedef EmojiSkinToneChanged = void Function(EmojiSkinTone skinTone);

class FlowyEmojiSearchBar extends StatefulWidget {
  const FlowyEmojiSearchBar({
    super.key,
    required this.emojiData,
    required this.onKeywordChanged,
    required this.onSkinToneChanged,
    required this.onRandomEmojiSelected,
  });

  final EmojiData emojiData;
  final EmojiKeywordChangedCallback onKeywordChanged;
  final EmojiSkinToneChanged onSkinToneChanged;
  final EmojiSelectedCallback onRandomEmojiSelected;

  @override
  State<FlowyEmojiSearchBar> createState() => _FlowyEmojiSearchBarState();
}

class _FlowyEmojiSearchBarState extends State<FlowyEmojiSearchBar> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: PlatformExtension.isDesktopOrWeb ? 0.0 : 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchTextField(
              onKeywordChanged: widget.onKeywordChanged,
            ),
          ),
          const HSpace(6.0),
          _RandomEmojiButton(
            emojiData: widget.emojiData,
            onRandomEmojiSelected: widget.onRandomEmojiSelected,
          ),
          const HSpace(6.0),
          FlowyEmojiSkinToneSelector(
            onEmojiSkinToneChanged: widget.onSkinToneChanged,
          ),
          const HSpace(6.0),
        ],
      ),
    );
  }
}

class _RandomEmojiButton extends StatelessWidget {
  const _RandomEmojiButton({
    required this.emojiData,
    required this.onRandomEmojiSelected,
  });

  final EmojiData emojiData;
  final EmojiSelectedCallback onRandomEmojiSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.emoji_random.tr(),
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: const Icon(
          Icons.shuffle_rounded,
        ),
        onTap: () {
          final random = emojiData.random;
          onRandomEmojiSelected(
            random.$1,
            random.$2,
          );
        },
      ),
    );
  }
}

class _SearchTextField extends StatefulWidget {
  const _SearchTextField({
    required this.onKeywordChanged,
  });

  final EmojiKeywordChangedCallback onKeywordChanged;

  @override
  State<_SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 32.0,
      ),
      child: FlowyTextField(
        focusNode: focusNode,
        hintText: LocaleKeys.emoji_search.tr(),
        controller: controller,
        onChanged: widget.onKeywordChanged,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            left: 8.0,
            right: 4.0,
          ),
          child: FlowySvg(
            FlowySvgs.search_s,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          maxHeight: 18.0,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FlowyButton(
            text: const FlowySvg(
              FlowySvgs.close_lg,
            ),
            margin: EdgeInsets.zero,
            useIntrinsicWidth: true,
            onTap: () {
              if (controller.text.isNotEmpty) {
                controller.clear();
                widget.onKeywordChanged('');
              } else {
                focusNode.unfocus();
              }
            },
          ),
        ),
      ),
    );
  }
}
