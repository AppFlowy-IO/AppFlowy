import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'layout_define.dart';

class RelatedQuestionList extends StatelessWidget {
  const RelatedQuestionList({
    super.key,
    required this.onQuestionSelected,
    required this.relatedQuestions,
  });

  final Function(String) onQuestionSelected;
  final List<String> relatedQuestions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: relatedQuestions.length + 1,
      padding:
          const EdgeInsets.only(bottom: 8.0) + AIChatUILayout.messageMargin,
      separatorBuilder: (context, index) => const VSpace(4.0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: FlowyText(
              LocaleKeys.chat_relatedQuestion.tr(),
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          );
        } else {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: RelatedQuestionItem(
              question: relatedQuestions[index - 1],
              onQuestionSelected: onQuestionSelected,
            ),
          );
        }
      },
    );
  }
}

class RelatedQuestionItem extends StatelessWidget {
  const RelatedQuestionItem({
    required this.question,
    required this.onQuestionSelected,
    super.key,
  });

  final String question;
  final Function(String) onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      mainAxisAlignment: MainAxisAlignment.start,
      text: Flexible(
        child: FlowyText(
          question,
          lineHeight: 1.4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      expandText: false,
      margin: UniversalPlatform.isMobile
          ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
          : const EdgeInsets.all(8.0),
      leftIcon: FlowySvg(
        FlowySvgs.ai_chat_outlined_s,
        color: Theme.of(context).colorScheme.primary,
        size: const Size.square(16.0),
      ),
      onTap: () => onQuestionSelected(question),
    );
  }
}
