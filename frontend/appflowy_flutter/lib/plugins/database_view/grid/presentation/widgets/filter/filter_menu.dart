import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_filter_list.dart';
import 'filter_menu_item.dart';

class FilterMenu extends StatelessWidget {
  final FieldController fieldController;
  const FilterMenu({
    required this.fieldController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GridFilterMenuBloc>(
      create: (context) => GridFilterMenuBloc(
        viewId: fieldController.viewId,
        fieldController: fieldController,
      )..add(
          const GridFilterMenuEvent.initial(),
        ),
      child: BlocBuilder<GridFilterMenuBloc, GridFilterMenuState>(
        builder: (context, state) {
          final List<Widget> children = [];
          children.addAll(
            state.filters
                .map((filterInfo) => FilterMenuItem(filterInfo: filterInfo))
                .toList(),
          );

          if (state.creatableFields.isNotEmpty) {
            children.add(AddFilterButton(viewId: state.viewId));
          }

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: children,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddFilterButton extends StatefulWidget {
  final String viewId;
  const AddFilterButton({required this.viewId, Key? key}) : super(key: key);

  @override
  State<AddFilterButton> createState() => _AddFilterButtonState();
}

class _AddFilterButtonState extends State<AddFilterButton> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return wrapPopover(
      context,
      SizedBox(
        height: 28,
        child: FlowyButton(
          text: FlowyText(
            LocaleKeys.grid_settings_addFilter.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          useIntrinsicWidth: true,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          leftIcon: svgWidget(
            "home/add",
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () => popoverController.show(),
        ),
      ),
    );
  }

  Widget wrapPopover(BuildContext buildContext, Widget child) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      margin: const EdgeInsets.all(6),
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (BuildContext context) {
        final bloc = buildContext.read<GridFilterMenuBloc>();
        return GridCreateFilterList(
          viewId: widget.viewId,
          fieldController: bloc.fieldController,
          onClosed: () => popoverController.close(),
        );
      },
    );
  }
}
