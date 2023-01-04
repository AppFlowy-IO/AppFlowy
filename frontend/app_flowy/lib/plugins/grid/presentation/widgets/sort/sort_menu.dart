import 'package:app_flowy/plugins/grid/application/sort/sort_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'dart:math' as math;

import 'sort_choice_button.dart';
import 'sort_editor.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortMenuBloc, SortMenuState>(
      builder: (context, state) {
        if (state.sortInfos.isNotEmpty) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(240, 200)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext popoverContext) {
              return SortEditor(
                viewId: state.viewId,
                fieldController: context.read<SortMenuBloc>().fieldController,
                sortInfos: state.sortInfos,
              );
            },
            child: SortChoiceChip(sortInfos: state.sortInfos),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class SortChoiceChip extends StatelessWidget {
  final List<SortInfo> sortInfos;
  final VoidCallback? onTap;

  const SortChoiceChip({
    Key? key,
    required this.sortInfos,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );

    final text = LocaleKeys.grid_settings_sort.tr();
    final leftIcon = svgWidget(
      "grid/setting/sort",
      color: Theme.of(context).colorScheme.onSurface,
    );

    return SizedBox(
      height: 28,
      child: SortChoiceButton(
        text: text,
        leftIcon: leftIcon,
        rightIcon: arrow,
        onTap: onTap,
      ),
    );
  }
}
