import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'item_visibility_detector.dart';

class MoreResultsItem extends StatelessWidget {
  const MoreResultsItem({
    super.key,
    required this.num,
    required this.onTap,
    required this.id,
  });

  final int num;
  final VoidCallback onTap;
  final String id;

  @override
  Widget build(BuildContext context) {
    final state = context.read<MentionBloc>().state;

    final theme = AppFlowyTheme.of(context);
    return MentionMenuItenVisibilityDetector(
      id: id,
      child: AFTextMenuItem(
        selected: state.selectedId == id,
        title: LocaleKeys.document_mentionMenu_moreResults.tr(args: ['$num']),
        titleColor: theme.textColorScheme.tertiary,
        onTap: onTap,
        leading: SizedBox.square(
          dimension: 24,
          child: Center(
            child: FlowySvg(
              FlowySvgs.mention_more_results_m,
              color: theme.iconColorScheme.tertiary,
              size: const Size.square(20.0),
            ),
          ),
        ),
        backgroundColor: context.mentionItemBGColor,
      ),
    );
  }
}
