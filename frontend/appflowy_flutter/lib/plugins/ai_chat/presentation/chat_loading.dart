import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An animated generating indicator for an AI response
class ChatAILoading extends StatelessWidget {
  const ChatAILoading({
    super.key,
    this.duration = const Duration(seconds: 1),
  });

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final slice = Duration(milliseconds: duration.inMilliseconds ~/ 5);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 20,
        child: SeparatedRow(
          separatorBuilder: () => const HSpace(4),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4.0),
              child: BlocBuilder<ChatAIMessageBloc, ChatAIMessageState>(
                builder: (context, state) {
                  return FlowyText(
                    state.progress?.step ??
                        LocaleKeys.chat_generatingResponse.tr(),
                    color: Theme.of(context).hintColor,
                  );
                },
              ),
            ),
            buildDot(const Color(0xFF9327FF))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice, begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0)
                .then()
                .slideY(duration: slice * 2, begin: 0, end: 0),
            buildDot(const Color(0xFFFB006D))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice, begin: 0, end: 0)
                .then()
                .slideY(begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0)
                .then()
                .slideY(begin: 0, end: 0),
            buildDot(const Color(0xFFFFCE00))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice * 2, begin: 0, end: 0)
                .then()
                .slideY(duration: slice, begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget buildDot(Color color) {
    return SizedBox.square(
      dimension: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
