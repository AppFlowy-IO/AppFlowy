import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class ChatErrorMessageWidget extends StatefulWidget {
  const ChatErrorMessageWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  State<ChatErrorMessageWidget> createState() => _ChatErrorMessageWidgetState();
}

class _ChatErrorMessageWidgetState extends State<ChatErrorMessageWidget> {
  late final TapGestureRecognizer recognizer;

  @override
  void initState() {
    super.initState();
    recognizer = TapGestureRecognizer()..onTap = widget.onRetry;
  }

  @override
  void dispose() {
    recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 24.0) +
            (UniversalPlatform.isMobile
                ? const EdgeInsets.symmetric(horizontal: 16)
                : EdgeInsets.zero),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).isLightMode
              ? const Color(0x80FFE7EE)
              : const Color(0x80591734),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
        constraints: UniversalPlatform.isDesktop
            ? const BoxConstraints(maxWidth: 480)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlowySvg(
              FlowySvgs.toast_error_filled_s,
              blendMode: null,
            ),
            const HSpace(8.0),
            Flexible(
              child: _buildText(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    final errorMessage = widget.errorMessage;

    return widget.onRetry != null
        ? RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextSpan(
                  text: ' ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextSpan(
                  text: LocaleKeys.chat_retry.tr(),
                  recognizer: recognizer,
                  mouseCursor: SystemMouseCursors.click,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ],
            ),
          )
        : FlowyText(
            errorMessage,
            lineHeight: 1.4,
            maxLines: null,
          );
  }
}
