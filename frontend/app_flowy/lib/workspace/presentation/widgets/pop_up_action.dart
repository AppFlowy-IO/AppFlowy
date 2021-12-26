import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:dartz/dartz.dart' as dartz;

abstract class ActionList<T extends ActionItem> {
  List<T> get items;

  String get identifier => toString();

  double get maxWidth => 162;

  double get itemHeight => ActionListSizes.itemHeight;

  ListOverlayFooter? get footer => null;

  void Function(dartz.Option<T>) get selectCallback;

  FlowyOverlayDelegate? get delegate;

  void show(
    BuildContext buildContext,
    BuildContext anchorContext, {
    AnchorDirection anchorDirection = AnchorDirection.bottomRight,
    Offset? anchorOffset,
  }) {
    final widgets = items
        .map(
          (action) => ActionCell<T>(
            action: action,
            itemHeight: itemHeight,
            onSelected: (action) {
              FlowyOverlay.of(buildContext).remove(identifier);
              selectCallback(dartz.some(action));
            },
          ),
        )
        .toList();

    ListOverlay.showWithAnchor(
      buildContext,
      identifier: identifier,
      itemCount: widgets.length,
      itemBuilder: (context, index) => widgets[index],
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      width: maxWidth,
      height: widgets.length * (itemHeight + ActionListSizes.padding * 2),
      delegate: delegate,
      anchorOffset: anchorOffset,
      footer: footer,
    );
  }
}

abstract class ActionItem {
  Widget? get icon;
  String get name;
}

class ActionListSizes {
  static double itemHPadding = 10;
  static double itemHeight = 20;
  static double padding = 6;
}

class ActionCell<T extends ActionItem> extends StatelessWidget {
  final T action;
  final Function(T) onSelected;
  final double itemHeight;
  const ActionCell({
    Key? key,
    required this.action,
    required this.onSelected,
    required this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FlowyHover(
      config: HoverDisplayConfig(hoverColor: theme.hover, borderColor: theme.shader2),
      builder: (context, onHover) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(action),
          child: SizedBox(
            height: itemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (action.icon != null) action.icon!,
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
