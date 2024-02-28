import 'package:flutter/material.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onSelected,
  });

  final SearchResultPB result;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final icon = result.getIcon();

    return ListTile(
      dense: true,
      title: Row(
        children: [
          if (icon != null) ...[icon, const HSpace(2)],
          FlowyText(result.data),
        ],
      ),
      focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      onTap: () {
        onSelected();

        // NotificationActionBloc can be renamed and made into
        // an overall ActionNavigationBloc or similar.
        getIt<ActionNavigationBloc>().add(
          ActionNavigationEvent.performAction(
            action: NavigationAction(objectId: result.viewId),
          ),
        );
      },
    );
  }
}
