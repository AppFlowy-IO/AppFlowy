import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class AIMessageMetadata extends StatelessWidget {
  const AIMessageMetadata({
    required this.sources,
    required this.onSelectedMetadata,
    super.key,
  });

  final List<ChatMessageRefSource> sources;
  final Function(ChatMessageRefSource metadata) onSelectedMetadata;
  @override
  Widget build(BuildContext context) {
    final title = sources.length == 1
        ? LocaleKeys.chat_referenceSource.tr(args: [sources.length.toString()])
        : LocaleKeys.chat_referenceSources
            .tr(args: [sources.length.toString()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sources.isNotEmpty)
          Opacity(
            opacity: 0.5,
            child: FlowyText(title, fontSize: 12),
          ),
        const VSpace(6),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sources
              .map(
                (m) => SizedBox(
                  height: 24,
                  child: FlowyButton(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    useIntrinsicWidth: true,
                    radius: BorderRadius.circular(6),
                    text: Opacity(
                      opacity: 0.5,
                      child: FlowyText(
                        m.name,
                        fontSize: 14,
                        lineHeight: 1.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onTap: () => onSelectedMetadata(m),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
