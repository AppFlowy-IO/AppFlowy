import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/sort/sort_menu_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'dart:math' as math;

import 'sort_choice_button.dart';
import 'sort_editor.dart';
import '../../../../application/sort/sort_info.dart';

class SortMenu extends StatelessWidget {
  final SortController sortController;
  final FieldController fieldController;

  const SortMenu({
    required this.fieldController,
    required this.sortController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SortMenuBloc>(
      create: (context) => SortMenuBloc(
        viewId: fieldController.viewId,
        sortController: sortController,
        fieldController: fieldController,
      )..add(const SortMenuEvent.initial()),
      child: BlocBuilder<SortMenuBloc, SortMenuState>(
        builder: (context, state) {
          if (state.sortInfos.isNotEmpty) {
            return AppFlowyPopover(
              controller: PopoverController(),
              constraints: BoxConstraints.loose(const Size(320, 200)),
              direction: PopoverDirection.bottomWithLeftAligned,
              offset: const Offset(0, 5),
              popupBuilder: (BuildContext popoverContext) {
                return SingleChildScrollView(
                  child: SortEditor(
                    viewId: state.viewId,
                    sortController: sortController,
                    fieldController:
                        context.read<SortMenuBloc>().fieldController,
                  ),
                );
              },
              child: SortChoiceChip(sortInfos: state.sortInfos),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class SortChoiceChip extends StatelessWidget {
  final List<SortInfo> sortInfos;
  final VoidCallback? onTap;

  const SortChoiceChip({
    super.key,
    required this.sortInfos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: FlowySvg(
        FlowySvgs.arrow_left_s,
        color: Theme.of(context).iconTheme.color,
      ),
    );

    final text = LocaleKeys.grid_settings_sort.tr();
    final leftIcon = FlowySvg(
      FlowySvgs.sort_ascending_s,
      color: Theme.of(context).iconTheme.color,
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
