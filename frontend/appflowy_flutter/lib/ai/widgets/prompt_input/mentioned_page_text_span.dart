import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

class PromptInputTextSpanBuilder extends SpecialTextSpanBuilder {
  PromptInputTextSpanBuilder({
    required this.inputControlCubit,
    this.mentionedPageTextStyle,
  });

  final ChatInputControlCubit inputControlCubit;
  final TextStyle? mentionedPageTextStyle;

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    int? index,
  }) {
    if (flag == '') {
      return null;
    }

    if (isStart(flag, MentionedPageText.flag)) {
      return MentionedPageText(
        inputControlCubit,
        mentionedPageTextStyle ?? textStyle,
        onTap,
        // scrubbing over text is kinda funky
        start: index! - (MentionedPageText.flag.length - 1),
      );
    }

    return null;
  }
}

class MentionedPageText extends SpecialText {
  MentionedPageText(
    this.inputControlCubit,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap, {
    this.start,
  }) : super(flag, '', textStyle, onTap: onTap);

  static const String flag = '@';

  final int? start;
  final ChatInputControlCubit inputControlCubit;

  @override
  bool isEnd(String value) => inputControlCubit.selectedViewIds.contains(value);

  @override
  InlineSpan finishText() {
    final String actualText = toString();

    final viewName = inputControlCubit.allViews
            .firstWhereOrNull((view) => view.id == actualText.substring(1))
            ?.name ??
        "";
    final nonEmptyName = viewName.isEmpty
        ? LocaleKeys.document_title_placeholder.tr()
        : viewName;

    return SpecialTextSpan(
      text: "@$nonEmptyName",
      actualText: actualText,
      start: start!,
      style: textStyle,
    );
  }
}
