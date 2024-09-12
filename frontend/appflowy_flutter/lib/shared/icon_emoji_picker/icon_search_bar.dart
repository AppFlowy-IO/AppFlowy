import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:universal_platform/universal_platform.dart';

import 'colors.dart';

typedef IconKeywordChangedCallback = void Function(String keyword);
typedef EmojiSkinToneChanged = void Function(EmojiSkinTone skinTone);

class IconSearchBar extends StatefulWidget {
  const IconSearchBar({
    super.key,
    required this.onRandomTap,
    required this.onKeywordChanged,
  });

  final VoidCallback onRandomTap;
  final IconKeywordChangedCallback onKeywordChanged;

  @override
  State<IconSearchBar> createState() => _IconSearchBarState();
}

class _IconSearchBarState extends State<IconSearchBar> {
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
        vertical: 12.0,
        horizontal: UniversalPlatform.isDesktopOrWeb ? 0.0 : 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchTextField(
              onKeywordChanged: widget.onKeywordChanged,
            ),
          ),
          const HSpace(8.0),
          _RandomIconButton(
            onRandomTap: widget.onRandomTap,
          ),
        ],
      ),
    );
  }
}

class _RandomIconButton extends StatelessWidget {
  const _RandomIconButton({
    required this.onRandomTap,
  });

  final VoidCallback onRandomTap;

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
          onTap: onRandomTap,
        ),
      ),
    );
  }
}

class _SearchTextField extends StatefulWidget {
  const _SearchTextField({
    required this.onKeywordChanged,
  });

  final IconKeywordChangedCallback onKeywordChanged;

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
