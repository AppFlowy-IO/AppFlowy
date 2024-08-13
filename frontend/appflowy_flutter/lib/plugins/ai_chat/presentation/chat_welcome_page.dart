import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'chat_input/chat_input.dart';

class WelcomeQuestion {
  WelcomeQuestion({
    required this.text,
    required this.iconData,
  });
  final String text;
  final FlowySvgData iconData;
}

class ChatWelcomePage extends StatelessWidget {
  ChatWelcomePage({
    required this.userProfile,
    required this.onSelectedQuestion,
    super.key,
  });

  final void Function(String) onSelectedQuestion;
  final UserProfilePB userProfile;

  final List<WelcomeQuestion> items = [
    WelcomeQuestion(
      text: LocaleKeys.chat_question1.tr(),
      iconData: FlowySvgs.chat_lightbulb_s,
    ),
    WelcomeQuestion(
      text: LocaleKeys.chat_question2.tr(),
      iconData: FlowySvgs.chat_scholar_s,
    ),
    WelcomeQuestion(
      text: LocaleKeys.chat_question3.tr(),
      iconData: FlowySvgs.chat_question_s,
    ),
    WelcomeQuestion(
      text: LocaleKeys.chat_question4.tr(),
      iconData: FlowySvgs.chat_feather_s,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(seconds: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Opacity(
              opacity: 0.8,
              child: FlowyText(
                fontSize: 15,
                LocaleKeys.chat_questionDetail.tr(args: [userProfile.name]),
              ),
            ),
            const VSpace(18),
            Opacity(
              opacity: 0.6,
              child: FlowyText(
                LocaleKeys.chat_questionTitle.tr(),
              ),
            ),
            const VSpace(8),
            Wrap(
              direction: Axis.vertical,
              children: items
                  .map(
                    (i) => WelcomeQuestionWidget(
                      question: i,
                      onSelected: onSelectedQuestion,
                    ),
                  )
                  .toList(),
            ),
            const VSpace(20),
          ],
        ),
      ),
    );
  }
}

class WelcomeQuestionWidget extends StatelessWidget {
  const WelcomeQuestionWidget({
    required this.question,
    required this.onSelected,
    super.key,
  });

  final void Function(String) onSelected;
  final WelcomeQuestion question;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelected(question.text),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: FlowyHover(
          // Make the hover effect only available on mobile
          isSelected: () => isMobile,
          style: HoverStyle(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlowySvg(
                  question.iconData,
                  size: const Size.square(18),
                  blendMode: null,
                ),
                const HSpace(16),
                FlowyText(
                  question.text,
                  maxLines: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
