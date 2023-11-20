import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
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
      child: SizedBox(
        height: 26,
        child: Row(
          children: [
            VerticalDivider(
              width: 1.0,
              thickness: 1.0,
              indent: 4.0,
              endIndent: 4.0,
              color: Theme.of(context).dividerColor,
            ),
            FlowyIconButton(
              width: 26,
              iconPadding: const EdgeInsets.all(5),
              hoverColor: AFThemeExtension.of(context).greyHover,
              onPressed: () => popoverController.show(),
              radius: Corners.s4Border,
              icon: const FlowySvg(FlowySvgs.add_s),
              iconColorOnHover: Theme.of(context).colorScheme.onSurface,
            ),
          ],
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
          '${LocaleKeys.grid_createView.tr()} ${action.title}',
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: FlowySvg(
          action.icon,
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

  FlowySvgData get icon {
    switch (this) {
      case AddButtonAction.board:
        return FlowySvgs.board_s;
      case AddButtonAction.calendar:
        return FlowySvgs.date_s;
      case AddButtonAction.grid:
        return FlowySvgs.grid_s;
    }
  }
}
