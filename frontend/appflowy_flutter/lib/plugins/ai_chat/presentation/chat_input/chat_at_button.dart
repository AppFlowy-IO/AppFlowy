import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class ChatInputAtButton extends StatelessWidget {
  const ChatInputAtButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_clickToMention.tr(),
      child: FlowyIconButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: BorderRadius.circular(6),
        icon: FlowySvg(
          FlowySvgs.chat_at_s,
          size: const Size.square(20),
          color: Colors.grey.shade600,
        ),
        onPressed: onTap,
      ),
    );
  }
}
