import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchRecentViewCell extends StatelessWidget {
  const SearchRecentViewCell({
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
    final theme = AppFlowyTheme.of(context),
        textColor = theme.textColorScheme.primary;
    final sapceM = theme.spacing.m, spaceL = theme.spacing.l;

    return AFBaseButton(
      borderRadius: sapceM,
      padding: EdgeInsets.symmetric(vertical: spaceL, horizontal: sapceM),
      backgroundColor: (context, isHovering, disable) {
        if (isHovering) {
          return Theme.of(context).colorScheme.secondary;
        }
        return theme.fillColorScheme.transparent;
      },
      borderColor: (context, isHovering, disable, isFocused) =>
          theme.fillColorScheme.transparent,
      builder: (ctx, isHovering, disable) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          HSpace(12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.nameOrDefault,
                  style: theme.textStyle.body.standard(color: textColor),
                ),
                buildPath(theme),
              ],
            ),
          ),
        ],
      ),
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

  Widget buildPath(AppFlowyThemeData theme) {
    return BlocProvider(
      create: (context) => ViewAncestorBloc(view.id),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) => state.buildPath(context),
      ),
    );
  }
}
