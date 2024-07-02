import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_loading.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'ai_text_editor.dart';
import 'selectable_highlight.dart';

class ChatAITextMessageWidget extends StatelessWidget {
  const ChatAITextMessageWidget({
    super.key,
    required this.user,
    required this.messageUserId,
    required this.text,
    required this.questionId,
    required this.chatId,
  });

  final User user;
  final String messageUserId;
  final dynamic text;
  final Int64? questionId;
  final String chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatAIMessageBloc(
        message: text,
        chatId: chatId,
        questionId: questionId,
      )..add(const ChatAIMessageEvent.initial()),
      child: BlocBuilder<ChatAIMessageBloc, ChatAIMessageState>(
        builder: (context, state) {
          if (state.error != null) {
            return StreamingError(
              onRetryPressed: () {
                context.read<ChatAIMessageBloc>().add(
                      const ChatAIMessageEvent.retry(),
                    );
              },
            );
          }

          if (state.retryState == const LoadingState.loading()) {
            return const ChatAILoading();
          }

          if (state.text.isEmpty) {
            return const ChatAILoading();
          } else {
            return AITextEditor(markdown: state.text);
          }
        },
      ),
    );
  }

  MarkdownConfig configFromContext(BuildContext context) {
    return MarkdownConfig(
      configs: [
        HrConfig(color: AFThemeExtension.of(context).textColor),
        ChatH1Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        ChatH2Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        ChatH3Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          dividerColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        H4Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        H5Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        H6Config(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        PreConfig(
          builder: (code, language) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 800,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                child: SelectableHighlightView(
                  code,
                  language: language,
                  theme: getHightlineTheme(context),
                  padding: const EdgeInsets.all(14),
                  textStyle: TextStyle(
                    color: AFThemeExtension.of(context).textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        PConfig(
          textStyle: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        CodeConfig(
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        BlockquoteConfig(
          sideColor: AFThemeExtension.of(context).lightGreyHover,
          textColor: AFThemeExtension.of(context).textColor,
        ),
      ],
    );
  }
}

Map<String, TextStyle> getHightlineTheme(BuildContext context) {
  return {
    'root': TextStyle(
      color: const Color(0xffabb2bf),
      backgroundColor:
          Theme.of(context).isLightMode ? Colors.white : Colors.black38,
    ),
    'comment':
        const TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
    'quote':
        const TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
    'doctag': const TextStyle(color: Color(0xffc678dd)),
    'keyword': const TextStyle(color: Color(0xffc678dd)),
    'formula': const TextStyle(color: Color(0xffc678dd)),
    'section': const TextStyle(color: Color(0xffe06c75)),
    'name': const TextStyle(color: Color(0xffe06c75)),
    'selector-tag': const TextStyle(color: Color(0xffe06c75)),
    'deletion': const TextStyle(color: Color(0xffe06c75)),
    'subst': const TextStyle(color: Color(0xffe06c75)),
    'literal': const TextStyle(color: Color(0xff56b6c2)),
    'string': const TextStyle(color: Color(0xff98c379)),
    'regexp': const TextStyle(color: Color(0xff98c379)),
    'addition': const TextStyle(color: Color(0xff98c379)),
    'attribute': const TextStyle(color: Color(0xff98c379)),
    'meta-string': const TextStyle(color: Color(0xff98c379)),
    'built_in': const TextStyle(color: Color(0xffe6c07b)),
    'attr': const TextStyle(color: Color(0xffd19a66)),
    'variable': const TextStyle(color: Color(0xffd19a66)),
    'template-variable': const TextStyle(color: Color(0xffd19a66)),
    'type': const TextStyle(color: Color(0xffd19a66)),
    'selector-class': const TextStyle(color: Color(0xffd19a66)),
    'selector-attr': const TextStyle(color: Color(0xffd19a66)),
    'selector-pseudo': const TextStyle(color: Color(0xffd19a66)),
    'number': const TextStyle(color: Color(0xffd19a66)),
    'symbol': const TextStyle(color: Color(0xff61aeee)),
    'bullet': const TextStyle(color: Color(0xff61aeee)),
    'link': const TextStyle(color: Color(0xff61aeee)),
    'meta': const TextStyle(color: Color(0xff61aeee)),
    'selector-id': const TextStyle(color: Color(0xff61aeee)),
    'title': const TextStyle(color: Color(0xff61aeee)),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
  };
}

class ChatH1Config extends HeadingConfig {
  const ChatH1Config({
    this.style = const TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });

  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h1.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}

///config class for h2
class ChatH2Config extends HeadingConfig {
  const ChatH2Config({
    this.style = const TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });
  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h2.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}

class ChatH3Config extends HeadingConfig {
  const ChatH3Config({
    this.style = const TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.bold,
    ),
    required this.dividerColor,
  });

  @override
  final TextStyle style;
  final Color dividerColor;

  @override
  String get tag => MarkdownTag.h3.name;

  @override
  HeadingDivider? get divider => HeadingDivider(
        space: 10,
        color: dividerColor,
        height: 10,
      );
}

class StreamingError extends StatelessWidget {
  const StreamingError({
    required this.onRetryPressed,
    super.key,
  });

  final void Function() onRetryPressed;
  @override
  Widget build(BuildContext context) {
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
