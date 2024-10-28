import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';

import '../sort/create_sort_list.dart';

class SortButton extends StatefulWidget {
  const SortButton({super.key, required this.toggleExtension});

  final ToggleExtensionNotifier toggleExtension;

  @override
  State<SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<SortButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        final textColor = state.sorts.isEmpty
            ? Theme.of(context).hintColor
            : Theme.of(context).colorScheme.primary;

        return wrapPopover(
          FlowyTextButton(
            LocaleKeys.grid_settings_sort.tr(),
            fontColor: textColor,
            fontSize: FontSizes.s12,
            fillColor: Colors.transparent,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            padding: GridSize.toolbarSettingButtonInsets,
            radius: Corners.s4Border,
            onPressed: () {
              if (state.sorts.isEmpty) {
                _popoverController.show();
              } else {
                widget.toggleExtension.toggle();
              }
            },
          ),
        );
      },
    );
  }

  Widget wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: _popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      offset: const Offset(0, 8),
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (popoverContext) {
        return BlocProvider.value(
          value: context.read<SortEditorBloc>(),
          child: CreateDatabaseViewSortList(
            onTap: () {
              if (!widget.toggleExtension.isToggled) {
                widget.toggleExtension.toggle();
              }
              _popoverController.close();
            },
          ),
        );
      },
      child: child,
    );
  }
}
