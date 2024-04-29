import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onSelected,
    this.isTrashed = false,
  });

  final SearchResultPB result;
  final VoidCallback onSelected;
  final bool isTrashed;

  @override
  Widget build(BuildContext context) {
    final icon = result.getIcon();

    return ListTile(
      dense: true,
      title: Row(
        children: [
          if (icon != null) ...[icon, const HSpace(6)],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTrashed) ...[
                FlowyText(
                  LocaleKeys.commandPalette_fromTrashHint.tr(),
                  color: AFThemeExtension.of(context).textColor.withAlpha(175),
                  fontSize: 10,
                ),
              ],
              FlowyText(result.data),
            ],
          ),
        ],
      ),
      focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      onTap: () {
        onSelected();

        getIt<ActionNavigationBloc>().add(
          ActionNavigationEvent.performAction(
            action: NavigationAction(objectId: result.viewId),
          ),
        );
      },
    );
  }
}
