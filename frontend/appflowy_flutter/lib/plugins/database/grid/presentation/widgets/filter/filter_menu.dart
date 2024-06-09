import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_filter_list.dart';
import 'filter_menu_item.dart';

class FilterMenu extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.fieldController,
  });

  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DatabaseFilterMenuBloc>(
      create: (context) => DatabaseFilterMenuBloc(
        viewId: fieldController.viewId,
        fieldController: fieldController,
      )..add(
          const DatabaseFilterMenuEvent.initial(),
        ),
      child: BlocBuilder<DatabaseFilterMenuBloc, DatabaseFilterMenuState>(
        builder: (context, state) {
          final List<Widget> children = [];
          children.addAll(
            state.filters
                .map(
                  (filterInfo) => FilterMenuItem(
                    key: ValueKey(filterInfo.filter.id),
                    filterInfo: filterInfo,
                  ),
                )
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
  const AddFilterButton({required this.viewId, super.key});

  final String viewId;

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
          leftIcon: FlowySvg(
            FlowySvgs.add_s,
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
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (BuildContext context) {
        final bloc = buildContext.read<DatabaseFilterMenuBloc>();
        return GridCreateFilterList(
          viewId: widget.viewId,
          fieldController: bloc.fieldController,
          onClosed: () => popoverController.close(),
        );
      },
    );
  }
}
