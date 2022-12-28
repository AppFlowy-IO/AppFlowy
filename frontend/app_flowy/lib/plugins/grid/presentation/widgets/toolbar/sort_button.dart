import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/sort/sort_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/sort/create_sort_list.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SortButton extends StatefulWidget {
  const SortButton({Key? key}) : super(key: key);

  @override
  State<SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<SortButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortMenuBloc, SortMenuState>(
      builder: (context, state) {
        final textColor = state.filters.isEmpty
            ? null
            : Theme.of(context).colorScheme.primary;

        return wrapPopover(
          context,
          SizedBox(
            height: 26,
            child: FlowyTextButton(
              LocaleKeys.grid_settings_sort.tr(),
              fontSize: 13,
              fontColor: textColor,
              fillColor: Colors.transparent,
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              onPressed: () {
                final bloc = context.read<SortMenuBloc>();
                if (bloc.state.filters.isEmpty) {
                  _popoverController.show();
                } else {
                  bloc.add(const SortMenuEvent.toggleMenu());
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
        final bloc = buildContext.read<SortMenuBloc>();
        return GridCreateSortList(
          viewId: bloc.viewId,
          fieldController: bloc.fieldController,
          onClosed: () => _popoverController.close(),
          onCreateSort: () {
            if (!bloc.state.isVisible) {
              bloc.add(const SortMenuEvent.toggleMenu());
            }
          },
        );
      },
    );
  }
}
