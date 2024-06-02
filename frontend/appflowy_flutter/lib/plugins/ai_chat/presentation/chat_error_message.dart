import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class ChatErrorMessage extends StatelessWidget {
  const ChatErrorMessage({required this.onRetryPressed, super.key});

  final void Function() onRetryPressed;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 4, thickness: 1),
        const VSpace(16),
        Center(
          child: FlowyTooltip(
            message: LocaleKeys.chat_clickToRetry.tr(),
            child: FlowyButton(
              useIntrinsicWidth: true,
              text: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlowyText(
                  LocaleKeys.chat_serverUnavailable.tr(),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                onRetryPressed();
              },
              iconPadding: 0,
              rightIcon: const Icon(
                Icons.refresh,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
