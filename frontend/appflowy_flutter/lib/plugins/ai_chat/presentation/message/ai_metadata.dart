import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:time/time.dart';

class AIMessageMetadata extends StatefulWidget {
  const AIMessageMetadata({
    required this.sources,
    required this.onSelectedMetadata,
    super.key,
  });

  final List<ChatMessageRefSource> sources;
  final void Function(ChatMessageRefSource metadata) onSelectedMetadata;

  @override
  State<AIMessageMetadata> createState() => _AIMessageMetadataState();
}

class _AIMessageMetadataState extends State<AIMessageMetadata> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 150.milliseconds,
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSpace(8.0),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 24,
              maxWidth: 240,
            ),
            child: FlowyButton(
              margin: const EdgeInsets.all(4.0),
              useIntrinsicWidth: true,
              radius: BorderRadius.circular(8.0),
              text: FlowyText(
                LocaleKeys.chat_referenceSource.plural(
                  widget.sources.length,
                  namedArgs: {'count': '${widget.sources.length}'},
                ),
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
              rightIcon: FlowySvg(
                isExpanded ? FlowySvgs.arrow_up_s : FlowySvgs.arrow_down_s,
                size: const Size.square(10),
              ),
              onTap: () {
                setState(() => isExpanded = !isExpanded);
              },
            ),
          ),
          if (isExpanded) ...[
            const VSpace(4.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.sources.map(
                (m) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 24,
                      maxWidth: 240,
                    ),
                    child: FlowyButton(
                      margin: const EdgeInsets.all(4.0),
                      useIntrinsicWidth: true,
                      radius: BorderRadius.circular(8.0),
                      text: FlowyText(
                        m.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leftIcon: FlowySvg(
                        FlowySvgs.icon_document_s,
                        size: const Size.square(16),
                        color: Theme.of(context).hintColor,
                      ),
                      disable: m.source != appflowySource,
                      onTap: () {
                        if (m.source != appflowySource) {
                          return;
                        }
                        widget.onSelectedMetadata(m);
                      },
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
