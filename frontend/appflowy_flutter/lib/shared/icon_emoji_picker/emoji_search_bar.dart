import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/emoji_skin_tone.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:universal_platform/universal_platform.dart';

import 'colors.dart';

typedef EmojiKeywordChangedCallback = void Function(String keyword);
typedef EmojiSkinToneChanged = void Function(EmojiSkinTone skinTone);

class FlowyEmojiSearchBar extends StatefulWidget {
  const FlowyEmojiSearchBar({
    super.key,
    this.ensureFocus = false,
    required this.emojiData,
    required this.onKeywordChanged,
    required this.onSkinToneChanged,
    required this.onRandomEmojiSelected,
  });

  final bool ensureFocus;
  final EmojiData emojiData;
  final EmojiKeywordChangedCallback onKeywordChanged;
  final EmojiSkinToneChanged onSkinToneChanged;
  final EmojiSelectedCallback onRandomEmojiSelected;

  @override
  State<FlowyEmojiSearchBar> createState() => _FlowyEmojiSearchBarState();
}

class _FlowyEmojiSearchBarState extends State<FlowyEmojiSearchBar> {
  final TextEditingController controller = TextEditingController();
  EmojiSkinTone skinTone = lastSelectedEmojiSkinTone ?? EmojiSkinTone.none;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: UniversalPlatform.isDesktopOrWeb ? 0.0 : 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchTextField(
              onKeywordChanged: widget.onKeywordChanged,
              ensureFocus: widget.ensureFocus,
            ),
          ),
          const HSpace(8.0),
          _RandomEmojiButton(
            skinTone: skinTone,
            emojiData: widget.emojiData,
            onRandomEmojiSelected: widget.onRandomEmojiSelected,
          ),
          const HSpace(8.0),
          FlowyEmojiSkinToneSelector(
            onEmojiSkinToneChanged: (v) {
              setState(() {
                skinTone = v;
              });
              widget.onSkinToneChanged.call(v);
            },
          ),
        ],
      ),
    );
  }
}

class _RandomEmojiButton extends StatelessWidget {
  const _RandomEmojiButton({
    required this.skinTone,
    required this.emojiData,
    required this.onRandomEmojiSelected,
  });

  final EmojiSkinTone skinTone;
  final EmojiData emojiData;
  final EmojiSelectedCallback onRandomEmojiSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: context.pickerButtonBoarderColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: FlowyTooltip(
        message: LocaleKeys.emoji_random.tr(),
        child: FlowyButton(
          useIntrinsicWidth: true,
          text: const FlowySvg(
            FlowySvgs.icon_shuffle_s,
          ),
          onTap: () {
            final random = emojiData.random;
            final emojiId = random.$1;
            final emoji = emojiData.getEmojiById(
              emojiId,
              skinTone: skinTone,
            );
            onRandomEmojiSelected(
              emojiId,
              emoji,
            );
          },
        ),
      ),
    );
  }
}

class _SearchTextField extends StatefulWidget {
  const _SearchTextField({
    required this.onKeywordChanged,
    this.ensureFocus = false,
  });

  final EmojiKeywordChangedCallback onKeywordChanged;
  final bool ensureFocus;

  @override
  State<_SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    /// Sometimes focus is lost due to the [SelectionGestureInterceptor] in [KeyboardServiceWidgetState]
    /// this is to ensure that focus can be regained within a short period of time
    if (widget.ensureFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || focusNode.hasFocus) return;
        focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.0,
      child: FlowyTextField(
        focusNode: focusNode,
        hintText: LocaleKeys.search_label.tr(),
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).hintColor,
            ),
        enableBorderColor: context.pickerSearchBarBorderColor,
        controller: controller,
        onChanged: widget.onKeywordChanged,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            left: 14.0,
            right: 8.0,
          ),
          child: FlowySvg(
            FlowySvgs.search_s,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          maxHeight: 20.0,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FlowyButton(
            text: const FlowySvg(
              FlowySvgs.m_app_bar_close_s,
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
