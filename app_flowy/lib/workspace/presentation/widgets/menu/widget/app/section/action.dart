import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/workspace/domain/view_edit.dart';

class ViewActionList implements FlowyOverlayDelegate {
  final Function(dartz.Option<ViewAction>) onSelected;
  final BuildContext anchorContext;
  final String _identifier = 'ViewActionList';

  const ViewActionList({required this.anchorContext, required this.onSelected});

  void show(BuildContext buildContext) {
    final items = ViewAction.values
        .map((action) => ActionItem(
            action: action,
            onSelected: (action) {
              FlowyOverlay.of(buildContext).remove(_identifier);
              onSelected(dartz.some(action));
            }))
        .toList();

    ListOverlay.showWithAnchor(
      buildContext,
      identifier: _identifier,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      anchorContext: anchorContext,
      anchorDirection: AnchorDirection.bottomRight,
      maxWidth: 162,
      maxHeight: ViewAction.values.length * 32,
      delegate: this,
    );
  }

  @override
  void didRemove() {
    onSelected(dartz.none());
  }
}

class ActionItem extends StatelessWidget {
  final ViewAction action;
  final Function(ViewAction) onSelected;
  const ActionItem({
    Key? key,
    required this.action,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FlowyHover(
      config: HoverDisplayConfig(hoverColor: theme.hover),
      builder: (context, onHover) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(action),
          child: Row(
            children: [
              action.icon,
              const HSpace(10),
              FlowyText.medium(
                action.name,
                fontSize: 12,
              ),
            ],
          ).padding(
            horizontal: 6,
            vertical: 6,
          ),
        );
      },
    );
  }
}
