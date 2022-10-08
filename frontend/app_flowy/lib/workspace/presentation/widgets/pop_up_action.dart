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

  double get maxWidth => 300;

  double get minWidth => 120;

  double get itemHeight => ActionListSizes.itemHeight;

  ListOverlayFooter? get footer => null;

  void Function(dartz.Option<T>) get selectCallback;

  FlowyOverlayDelegate? get delegate;

  void show(
    BuildContext buildContext, {
    BuildContext? anchorContext,
    AnchorDirection anchorDirection = AnchorDirection.bottomRight,
    Offset? anchorOffset,
  }) {
    ListOverlay.showWithAnchor(
      buildContext,
      identifier: identifier,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final action = items[index];
        return ActionCell<T>(
          action: action,
          itemHeight: itemHeight,
          onSelected: (action) {
            FlowyOverlay.of(buildContext).remove(identifier);
            selectCallback(dartz.some(action));
          },
        );
      },
      anchorContext: anchorContext ?? buildContext,
      anchorDirection: anchorDirection,
      constraints: BoxConstraints(
        minHeight: items.length * (itemHeight + ActionListSizes.vPadding * 2),
        maxHeight: items.length * (itemHeight + ActionListSizes.vPadding * 2),
        maxWidth: maxWidth,
        minWidth: minWidth,
      ),
      delegate: delegate,
      anchorOffset: anchorOffset,
      footer: footer,
    );
  }
}

abstract class ActionItem {
  Widget? icon(Color iconColor);
  String get name;
}

class ActionListSizes {
  static double itemHPadding = 10;
  static double itemHeight = 20;
  static double vPadding = 6;
  static double hPadding = 10;
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
    final icon = action.icon(theme.iconColor);

    return FlowyHover(
      style: HoverStyle(hoverColor: theme.hover),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(action),
        child: SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              if (icon != null) ...[icon, HSpace(ActionListSizes.itemHPadding)],
              FlowyText.medium(action.name, fontSize: 12),
            ],
          ),
        ).padding(
          horizontal: ActionListSizes.hPadding,
          vertical: ActionListSizes.vPadding,
        ),
      ),
    );
  }
}
