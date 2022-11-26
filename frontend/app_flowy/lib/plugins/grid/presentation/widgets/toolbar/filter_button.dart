import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../filter/create_filter_list.dart';

class FilterButton extends StatefulWidget {
  const FilterButton({Key? key}) : super(key: key);

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridFilterMenuBloc, GridFilterMenuState>(
      builder: (context, state) {
        final textColor = state.filters.isEmpty
            ? null
            : Theme.of(context).colorScheme.primary;

        return wrapPopover(
          context,
          SizedBox(
            height: 26,
            child: FlowyTextButton(
              LocaleKeys.grid_settings_filter.tr(),
              fontSize: 14,
              fontColor: textColor,
              fillColor: Colors.transparent,
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              onPressed: () {
                final bloc = context.read<GridFilterMenuBloc>();
                if (bloc.state.filters.isEmpty) {
                  _popoverController.show();
                } else {
                  bloc.add(const GridFilterMenuEvent.toggleMenu());
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget wrapPopover(BuildContext buildContext, Widget child) {
    return AppFlowyPopover(
      controller: _popoverController,
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      offset: const Offset(0, 10),
      margin: const EdgeInsets.all(6),
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (BuildContext context) {
        final bloc = buildContext.read<GridFilterMenuBloc>();
        return GridCreateFilterList(
          viewId: bloc.viewId,
          fieldController: bloc.fieldController,
          onClosed: () => _popoverController.close(),
        );
      },
    );
  }
}
