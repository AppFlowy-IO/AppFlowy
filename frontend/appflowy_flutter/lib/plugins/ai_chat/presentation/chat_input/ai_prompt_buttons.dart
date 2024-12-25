import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';

import '../layout_define.dart';

enum SendButtonState { enabled, streaming, disabled }

class PromptInputAttachmentButton extends StatelessWidget {
  const PromptInputAttachmentButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_uploadFile.tr(),
      child: SizedBox.square(
        dimension: DesktopAIPromptSizes.actionBarButtonSize,
        child: FlowyIconButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          radius: BorderRadius.circular(8),
          icon: FlowySvg(
            FlowySvgs.ai_attachment_s,
            size: const Size.square(16),
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class PromptInputMentionButton extends StatelessWidget {
  const PromptInputMentionButton({
    super.key,
    required this.buttonSize,
    required this.iconSize,
    required this.onTap,
  });

  final double buttonSize;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_clickToMention.tr(),
      preferBelow: false,
      child: FlowyIconButton(
        width: buttonSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: BorderRadius.circular(8),
        icon: FlowySvg(
          FlowySvgs.chat_at_s,
          size: Size.square(iconSize),
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class PromptInputSendButton extends StatelessWidget {
  const PromptInputSendButton({
    super.key,
    required this.buttonSize,
    required this.iconSize,
    required this.state,
    required this.onSendPressed,
    required this.onStopStreaming,
  });

  final double buttonSize;
  final double iconSize;
  final SendButtonState state;
  final VoidCallback onSendPressed;
  final VoidCallback onStopStreaming;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: buttonSize,
      icon: switch (state) {
        SendButtonState.enabled => FlowySvg(
            FlowySvgs.ai_send_filled_s,
            size: Size.square(iconSize),
            color: Theme.of(context).colorScheme.primary,
          ),
        SendButtonState.disabled => FlowySvg(
            FlowySvgs.ai_send_filled_s,
            size: Size.square(iconSize),
            color: Theme.of(context).disabledColor,
          ),
        SendButtonState.streaming => FlowySvg(
            FlowySvgs.ai_stop_filled_s,
            size: Size.square(iconSize),
            color: Theme.of(context).colorScheme.primary,
          ),
      },
      onPressed: () {
        switch (state) {
          case SendButtonState.enabled:
            onSendPressed();
            break;
          case SendButtonState.streaming:
            onStopStreaming();
            break;
          case SendButtonState.disabled:
            break;
        }
      },
      hoverColor: Colors.transparent,
    );
  }
}
