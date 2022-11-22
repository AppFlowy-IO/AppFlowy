import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../toolbar/grid_create_filter_list.dart';
import 'menu_item.dart';

class GridFilterMenu extends StatelessWidget {
  const GridFilterMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridFilterMenuBloc, GridFilterMenuState>(
      builder: (context, state) {
        if (state.isVisible) {
          final List<Widget> children = state.filters
              .map((filter) => FilterMenuItem(filter: filter))
              .toList();

          return Row(
            children: [
              SizedBox(width: GridSize.leadingHeaderPadding),
              SingleChildScrollView(
                controller: ScrollController(),
                scrollDirection: Axis.horizontal,
                child: Wrap(spacing: 4, children: children),
              ),
              AddFilterButton(viewId: state.viewId),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
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
      FlowyTextButton(
        LocaleKeys.grid_settings_addFilter.tr(),
        fontSize: 14,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onPressed: () {
          popoverController.show();
        },
      ),
    );
  }

  Widget wrapPopover(BuildContext buildContext, Widget child) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(260, 300)),
      margin: const EdgeInsets.all(6),
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (BuildContext context) {
        final bloc = buildContext.read<GridFilterMenuBloc>();
        return GridCreateFilterList(
          viewId: widget.viewId,
          fieldController: bloc.fieldController,
        );
      },
    );
  }
}
