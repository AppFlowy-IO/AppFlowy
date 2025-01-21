import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'layout_define.dart';

enum SendButtonState { enabled, streaming, disabled }

class PromptInputSendButton extends StatelessWidget {
  const PromptInputSendButton({
    super.key,
    required this.state,
    required this.onSendPressed,
    required this.onStopStreaming,
  });

  final SendButtonState state;
  final VoidCallback onSendPressed;
  final VoidCallback onStopStreaming;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: _buttonSize,
      icon: switch (state) {
        SendButtonState.enabled => FlowySvg(
            FlowySvgs.ai_send_filled_s,
            size: Size.square(_iconSize),
            color: Theme.of(context).colorScheme.primary,
          ),
        SendButtonState.disabled => FlowySvg(
            FlowySvgs.ai_send_filled_s,
            size: Size.square(_iconSize),
            color: Theme.of(context).disabledColor,
          ),
        SendButtonState.streaming => FlowySvg(
            FlowySvgs.ai_stop_filled_s,
            size: Size.square(_iconSize),
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

  double get _buttonSize {
    return UniversalPlatform.isMobile
        ? MobileAIPromptSizes.sendButtonSize
        : DesktopAIPromptSizes.actionBarSendButtonSize;
  }

  double get _iconSize {
    return UniversalPlatform.isMobile
        ? MobileAIPromptSizes.sendButtonSize
        : DesktopAIPromptSizes.actionBarSendButtonIconSize;
  }
}
