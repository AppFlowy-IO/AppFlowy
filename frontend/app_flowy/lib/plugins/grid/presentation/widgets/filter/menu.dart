import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_filter_list.dart';
import 'menu_item.dart';

class GridFilterMenu extends StatelessWidget {
  const GridFilterMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridFilterMenuBloc, GridFilterMenuState>(
      builder: (context, state) {
        if (state.isVisible) {
          return _wrapPadding(Column(
            children: [
              buildDivider(context),
              const VSpace(6),
              buildFilterItems(state.viewId, state),
            ],
          ));
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _wrapPadding(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GridSize.leadingHeaderPadding,
        vertical: 6,
      ),
      child: child,
    );
  }

  Widget buildDivider(BuildContext context) {
    return Divider(
      height: 1.0,
      color: AFThemeExtension.of(context).toggleOffFill,
    );
  }

  Widget buildFilterItems(String viewId, GridFilterMenuState state) {
    final List<Widget> children = [];
    children.addAll(
      state.filters
          .map((filterInfo) => FilterMenuItem(filterInfo: filterInfo))
          .toList(),
    );

    if (state.creatableFields.isNotEmpty) {
      children.add(AddFilterButton(viewId: viewId));
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: children,
          ),
        ),
      ],
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
          text: FlowyText(LocaleKeys.grid_settings_addFilter.tr()),
          useIntrinsicWidth: true,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          leftIcon: svgWidget(
            "home/add",
            color: Theme.of(context).colorScheme.onSurface,
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
