import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji_skin_tone.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_mart/emoji_mart.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyEmojiSearchBar extends StatefulWidget {
  const FlowyEmojiSearchBar({
    super.key,
    required this.onKeywordChanged,
    required this.onSkinToneChanged,
  });

  final void Function(String keyword) onKeywordChanged;
  final void Function(EmojiSkinTone skinTone) onSkinToneChanged;

  @override
  State<FlowyEmojiSearchBar> createState() => _FlowyEmojiSearchBarState();
}

class _FlowyEmojiSearchBarState extends State<FlowyEmojiSearchBar> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: FlowyTextField(
              autoFocus: true,
              hintText: LocaleKeys.emoji_search.tr(),
              controller: controller,
              onChanged: widget.onKeywordChanged,
            ),
          ),
          const HSpace(6.0),
          SizedBox.square(
            dimension: 32,
            child: FlowyButton(
              text: const FlowySvg(
                FlowySvgs.close_lg,
              ),
              margin: EdgeInsets.zero,
              useIntrinsicWidth: true,
              onTap: () {
                controller.clear();
                widget.onKeywordChanged('');
              },
            ),
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
