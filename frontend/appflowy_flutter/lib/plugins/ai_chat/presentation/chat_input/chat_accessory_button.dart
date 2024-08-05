import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

class ChatInputAccessoryButton extends StatelessWidget {
  const ChatInputAccessoryButton({
    required this.onSendPressed,
    required this.onStopStreaming,
    required this.isStreaming,
    super.key,
  });

  final void Function() onSendPressed;
  final void Function() onStopStreaming;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    if (isStreaming) {
      return FlowyIconButton(
        width: 36,
        icon: FlowySvg(
          FlowySvgs.ai_stream_stop_s,
          size: const Size.square(28),
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: onStopStreaming,
        radius: BorderRadius.circular(18),
        fillColor: AFThemeExtension.of(context).lightGreyHover,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
      );
    } else {
      return FlowyIconButton(
        width: 36,
        fillColor: AFThemeExtension.of(context).lightGreyHover,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: BorderRadius.circular(18),
        icon: FlowySvg(
          FlowySvgs.send_s,
          size: const Size.square(24),
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: onSendPressed,
      );
    }
  }
}
