import 'package:flutter/material.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class RecentViewTile extends StatelessWidget {
  const RecentViewTile({
    super.key,
    required this.icon,
    required this.view,
    required this.onSelected,
  });

  final Widget icon;
  final ViewPB view;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          icon,
          const HSpace(6),
          FlowyText(view.name),
        ],
      ),
      focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        onSelected();

        getIt<ActionNavigationBloc>().add(
          ActionNavigationEvent.performAction(
            action: NavigationAction(objectId: view.id),
          ),
        );
      },
    );
  }
}
