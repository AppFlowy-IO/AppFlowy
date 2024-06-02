import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_related_question_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RelatedQuestionList extends StatefulWidget {
  const RelatedQuestionList({
    required this.chatId,
    required this.onQuestionSelected,
    super.key,
  });

  final String chatId;
  final Function(String) onQuestionSelected;

  @override
  State<RelatedQuestionList> createState() => _RelatedQuestionListState();
}

class _RelatedQuestionListState extends State<RelatedQuestionList> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatRelatedMessageBloc(chatId: widget.chatId)
        ..add(
          const ChatRelatedMessageEvent.initial(),
        ),
      child: BlocBuilder<ChatRelatedMessageBloc, ChatRelatedMessageState>(
        builder: (blocContext, state) {
          if (state.relatedQuestions.isEmpty) {
            return const SizedBox.shrink();
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const FlowySvg(
                        FlowySvgs.ai_summary_generate_s,
                        size: Size.square(24),
                      ),
                      const HSpace(6),
                      FlowyText(
                        LocaleKeys.chat_relatedQuestion.tr(),
                        fontSize: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 6),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.relatedQuestions.length,
                  itemBuilder: (context, index) {
                    final question = state.relatedQuestions[index];
                    return ListTile(
                      title: Text(question.content),
                      onTap: () {
                        widget.onQuestionSelected(question.content);
                        blocContext.read<ChatRelatedMessageBloc>().add(
                              const ChatRelatedMessageEvent.clear(),
                            );
                      },
                      trailing: const FlowySvg(FlowySvgs.add_m),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
