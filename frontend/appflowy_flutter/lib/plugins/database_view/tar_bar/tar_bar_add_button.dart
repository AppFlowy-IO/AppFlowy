import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/material.dart';

class AddDatabaseViewButton extends StatefulWidget {
  final Function(AddButtonAction) onTap;
  const AddDatabaseViewButton({
    required this.onTap,
    super.key,
  });

  @override
  State<AddDatabaseViewButton> createState() => _AddDatabaseViewButtonState();
}

class _AddDatabaseViewButtonState extends State<AddDatabaseViewButton> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(200, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 8),
      margin: EdgeInsets.zero,
      triggerActions: PopoverTriggerFlags.none,
      child: FlowyIconButton(
        iconPadding: const EdgeInsets.all(4),
        hoverColor: AFThemeExtension.of(context).greyHover,
        onPressed: () => popoverController.show(),
        icon: svgWidget(
          'home/add',
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
      popupBuilder: (BuildContext context) {
        return TarBarAddButtonAction(
          onTap: (action) {
            popoverController.close();
            widget.onTap(action);
          },
        );
      },
    );
  }
}

class TarBarAddButtonAction extends StatelessWidget {
  final Function(AddButtonAction) onTap;
  const TarBarAddButtonAction({
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cells = AddButtonAction.values.map((layout) {
      return TarBarAddButtonActionCell(
        action: layout,
        onTap: onTap,
      );
    }).toList();

    return ListView.separated(
      controller: ScrollController(),
      shrinkWrap: true,
      itemCount: cells.length,
      itemBuilder: (BuildContext context, int index) => cells[index],
      separatorBuilder: (BuildContext context, int index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      padding: const EdgeInsets.symmetric(vertical: 6.0),
    );
  }
}

class TarBarAddButtonActionCell extends StatelessWidget {
  final AddButtonAction action;
  final void Function(AddButtonAction) onTap;
  const TarBarAddButtonActionCell({
    required this.action,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          action.title,
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: svgWidget(
          action.iconName,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: () => onTap(action),
      ).padding(horizontal: 6.0),
    );
  }
}

enum AddButtonAction {
  grid,
  calendar,
  board;

  String get title {
    switch (this) {
      case AddButtonAction.board:
        return LocaleKeys.board_menuName.tr();
      case AddButtonAction.calendar:
        return LocaleKeys.calendar_menuName.tr();
      case AddButtonAction.grid:
        return LocaleKeys.grid_menuName.tr();
      default:
        return "";
    }
  }

  ViewLayoutPB get layoutType {
    switch (this) {
      case AddButtonAction.board:
        return ViewLayoutPB.Board;
      case AddButtonAction.calendar:
        return ViewLayoutPB.Calendar;
      case AddButtonAction.grid:
        return ViewLayoutPB.Grid;
      default:
        return ViewLayoutPB.Grid;
    }
  }

  String get iconName {
    switch (this) {
      case AddButtonAction.board:
        return 'editor/board';
      case AddButtonAction.calendar:
        return "editor/grid";
      case AddButtonAction.grid:
        return "editor/grid";
      default:
        return "";
    }
  }
}
