import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/material.dart';

class AddDatabaseViewButton extends StatefulWidget {
  const AddDatabaseViewButton({super.key, required this.onTap});

  final Function(DatabaseLayoutPB) onTap;

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
        return TabBarAddButtonAction(
          onTap: (action) {
            popoverController.close();
            widget.onTap(action);
          },
        );
      },
    );
  }
}

class TabBarAddButtonAction extends StatelessWidget {
  const TabBarAddButtonAction({super.key, required this.onTap});

  final Function(DatabaseLayoutPB) onTap;

  @override
  Widget build(BuildContext context) {
    final cells = DatabaseLayoutPB.values.map((layout) {
      return TabBarAddButtonActionCell(
        action: layout,
        onTap: onTap,
      );
    }).toList();

    return ListView.separated(
      shrinkWrap: true,
      itemCount: cells.length,
      itemBuilder: (BuildContext context, int index) => cells[index],
      separatorBuilder: (BuildContext context, int index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      padding: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }
}

class TabBarAddButtonActionCell extends StatelessWidget {
  const TabBarAddButtonActionCell({
    super.key,
    required this.action,
    required this.onTap,
  });

  final DatabaseLayoutPB action;
  final void Function(DatabaseLayoutPB) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          '${LocaleKeys.grid_createView.tr()} ${action.layoutName}',
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
