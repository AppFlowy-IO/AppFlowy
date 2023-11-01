import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

enum FlowyIconType {
  emoji,
  icon,
  custom;
}

class FlowyIconPicker extends StatefulWidget {
  const FlowyIconPicker({
    super.key,
    required this.onSelected,
  });

  final void Function(FlowyIconType type, String value) onSelected;

  @override
  State<FlowyIconPicker> createState() => _FlowyIconPickerState();
}

class _FlowyIconPickerState extends State<FlowyIconPicker>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ONLY supports emoji picker for now
    return DefaultTabController(
      length: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildTabs(context),
              const Spacer(),
              _RemoveIconButton(
                onTap: () {
                  widget.onSelected(FlowyIconType.icon, '');
                },
              ),
            ],
          ),
          const Divider(
            height: 2,
          ),
          Expanded(
            child: TabBarView(
              children: [
                FlowyEmojiPicker(
                  onEmojiSelected: (_, emoji) {
                    widget.onSelected(FlowyIconType.emoji, emoji);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        overlayColor: MaterialStatePropertyAll(
          Theme.of(context).colorScheme.secondary,
        ),
        padding: EdgeInsets.zero,
        tabs: [
          FlowyHover(
            style: const HoverStyle(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: FlowyText(
                LocaleKeys.emoji_emojiTab.tr(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _RemoveIconButton extends StatelessWidget {
  const _RemoveIconButton({
    required this.onTap,
  });

  final VoidCallback onTap;
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
        leftIcon: const FlowySvg(FlowySvgs.delete_s),
      ),
    );
  }
}
