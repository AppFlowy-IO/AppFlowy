import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:universal_platform/universal_platform.dart';

class ChatInvalidUserMessage extends StatelessWidget {
  const ChatInvalidUserMessage({
    required this.message,
    super.key,
  });

  final Message message;
  @override
  Widget build(BuildContext context) {
    final errorMessage = message.metadata?[sendMessageErrorKey] ?? "";
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 24.0),
        constraints: UniversalPlatform.isDesktop
            ? const BoxConstraints(maxWidth: 480)
            : const BoxConstraints(),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).isLightMode
              ? const Color(0x80FFE7EE)
              : const Color(0x80591734),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlowySvg(
              FlowySvgs.warning_filled_s,
              blendMode: null,
            ),
            const HSpace(8.0),
            Flexible(
              child: FlowyText(
                errorMessage,
                lineHeight: 1.4,
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
