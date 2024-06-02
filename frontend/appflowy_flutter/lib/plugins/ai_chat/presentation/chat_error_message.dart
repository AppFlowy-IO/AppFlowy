import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatErrorMessage extends StatelessWidget {
  const ChatErrorMessage({
    required this.message,
    required this.onRetryPressed,
    super.key,
  });

  final void Function() onRetryPressed;
  final Message message;
  @override
  Widget build(BuildContext context) {
    final canRetry = message.metadata?["canRetry"] != null;

    if (canRetry) {
      return Column(
        children: [
          const Divider(height: 4, thickness: 1),
          const VSpace(16),
          Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlowyText(
                    LocaleKeys.chat_aiServerUnavailable.tr(),
                    fontSize: 14,
                  ),
                ),
                const VSpace(10),
                FlowyButton(
                  radius: BorderRadius.circular(20),
                  useIntrinsicWidth: true,
                  text: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                ),
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
}
