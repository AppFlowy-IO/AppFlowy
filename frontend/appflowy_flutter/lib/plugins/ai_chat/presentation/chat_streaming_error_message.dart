import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatStreamingError extends StatelessWidget {
  const ChatStreamingError({
    required this.message,
    required this.onRetryPressed,
    super.key,
  });

  final void Function() onRetryPressed;
  final Message message;
  @override
  Widget build(BuildContext context) {
    final canRetry = message.metadata?[canRetryKey] != null;

    if (canRetry) {
      return Column(
        children: [
          const Divider(height: 4, thickness: 1),
          const VSpace(16),
          Center(
            child: Column(
              children: [
                _aiUnvaliable(),
                const VSpace(10),
                _retryButton(),
              ],
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          children: [
            const Divider(height: 20, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FlowyText(
                LocaleKeys.chat_serverUnavailable.tr(),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }

  FlowyButton _retryButton() {
    return FlowyButton(
      radius: BorderRadius.circular(20),
      useIntrinsicWidth: true,
      text: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: FlowyText(
          LocaleKeys.chat_regenerateAnswer.tr(),
          fontSize: 14,
        ),
      ),
      onTap: onRetryPressed,
      iconPadding: 0,
      leftIcon: const Icon(
        Icons.refresh,
        size: 20,
      ),
    );
  }

  Padding _aiUnvaliable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FlowyText(
        LocaleKeys.chat_aiServerUnavailable.tr(),
        fontSize: 14,
      ),
    );
  }
}
