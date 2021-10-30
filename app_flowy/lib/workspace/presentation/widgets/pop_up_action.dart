import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:dartz/dartz.dart' as dartz;

abstract class ActionList<T extends ActionItemData> {
  List<T> get items;

  String get identifier;

  double get maxWidth;

  void Function(dartz.Option<T>) get selectCallback;

  FlowyOverlayDelegate? get delegate;

  void show(BuildContext buildContext, BuildContext anchorContext,
      {AnchorDirection anchorDirection = AnchorDirection.bottomRight}) {
    final widgets = items
        .map((action) => ActionItem<T>(
            action: action,
            onSelected: (action) {
              FlowyOverlay.of(buildContext).remove(identifier);
              selectCallback(dartz.some(action));
            }))
        .toList();

    double totalHeight = widgets.length * (ActionListSizes.itemHeight + ActionListSizes.padding * 2);

    ListOverlay.showWithAnchor(
      buildContext,
      identifier: identifier,
      itemCount: widgets.length,
      itemBuilder: (context, index) => widgets[index],
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      maxWidth: maxWidth,
      maxHeight: totalHeight,
      delegate: delegate,
    );
  }
}

abstract class ActionItemData {
  Widget get icon;
  String get name;
}

class ActionListSizes {
  static double itemHPadding = 10;
  static double itemHeight = 16;
  static double padding = 6;
}

class ActionItem<T extends ActionItemData> extends StatelessWidget {
  final T action;
  final Function(T) onSelected;
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
          child: SizedBox(
            height: ActionListSizes.itemHeight,
            child: Row(
              children: [
                action.icon,
                HSpace(ActionListSizes.itemHPadding),
                FlowyText.medium(
                  action.name,
                  fontSize: 12,
                ),
              ],
            ),
          ).padding(
            horizontal: ActionListSizes.padding,
            vertical: ActionListSizes.padding,
          ),
        );
      },
    );
  }
}
