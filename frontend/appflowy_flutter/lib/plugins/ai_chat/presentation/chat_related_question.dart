import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class RelatedQuestionList extends StatelessWidget {
  const RelatedQuestionList({
    required this.onQuestionSelected,
    required this.relatedQuestions,
    super.key,
  });

  final Function(String) onQuestionSelected;
  final List<RelatedQuestionPB> relatedQuestions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: relatedQuestions.length,
      itemBuilder: (context, index) {
        final question = relatedQuestions[index];
        if (index == 0) {
          return Column(
            children: [
              const Divider(height: 36),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    FlowySvg(
                      FlowySvgs.ai_summary_generate_s,
                      size: const Size.square(24),
                      color: Theme.of(context).colorScheme.primary,
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
              RelatedQuestionItem(
                question: question,
                onQuestionSelected: onQuestionSelected,
              ),
            ],
          );
        } else {
          return RelatedQuestionItem(
            question: question,
            onQuestionSelected: onQuestionSelected,
          );
        }
      },
    );
  }
}

class RelatedQuestionItem extends StatefulWidget {
  const RelatedQuestionItem({
    required this.question,
    required this.onQuestionSelected,
    super.key,
  });

  final RelatedQuestionPB question;
  final Function(String) onQuestionSelected;

  @override
  State<RelatedQuestionItem> createState() => _RelatedQuestionItemState();
}

class _RelatedQuestionItemState extends State<RelatedQuestionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        title: Text(
          widget.question.content,
          style: TextStyle(
            color: _isHovered ? Theme.of(context).colorScheme.primary : null,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        onTap: () {
          widget.onQuestionSelected(widget.question.content);
        },
        trailing: FlowySvg(
          FlowySvgs.add_m,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
