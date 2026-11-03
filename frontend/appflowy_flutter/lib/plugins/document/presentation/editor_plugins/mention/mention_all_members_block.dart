import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MentionAllMembersBlock extends StatelessWidget {
  const MentionAllMembersBlock({
    super.key,
    required this.mention,
    this.textStyle,
  });

  final Map<String, dynamic> mention;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final label = mention[MentionBlockKeys.label] as String? ?? 'all';
    final effectiveStyle = textStyle?.copyWith(
      leadingDistribution: TextLeadingDistribution.even,
    );

    final iconSize = (textStyle?.fontSize ?? 14.0) / 14.0 * 16.0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '@$label',
          style: effectiveStyle,
          strutStyle: effectiveStyle != null
              ? StrutStyle.fromTextStyle(effectiveStyle)
              : null,
        ),
        const HSpace(4),
        FlowySvg(
          FlowySvgs.settings_members_m,
          size: Size.square(iconSize),
          color: effectiveStyle?.color,
        ),
      ],
    );
  }
}
