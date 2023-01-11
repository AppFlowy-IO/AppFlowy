import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/sort/sort_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/sort/util.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/sort/create_sort_list.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/sort_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import 'order_panel.dart';
import 'sort_choice_button.dart';
import 'sort_info.dart';

class SortEditor extends StatefulWidget {
  final String viewId;
  final List<SortInfo> sortInfos;
  final GridFieldController fieldController;
  const SortEditor({
    required this.viewId,
    required this.fieldController,
    required this.sortInfos,
    Key? key,
  }) : super(key: key);

  @override
  State<SortEditor> createState() => _SortEditorState();
}

class _SortEditorState extends State<SortEditor> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SortEditorBloc(
        viewId: widget.viewId,
        fieldController: widget.fieldController,
        sortInfos: widget.sortInfos,
      )..add(const SortEditorEvent.initial()),
      child: BlocBuilder<SortEditorBloc, SortEditorState>(
        builder: (context, state) {
          return IntrinsicWidth(
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _SortList(popoverMutex: popoverMutex),
                  _AddSortButton(
                    viewId: widget.viewId,
                    fieldController: widget.fieldController,
                    popoverMutex: popoverMutex,
                  ),
                  _DeleteSortButton(popoverMutex: popoverMutex),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortList extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const _SortList({required this.popoverMutex, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        final List<Widget> children = state.sortInfos
            .map((info) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _SortItem(
                    sortInfo: info,
                    popoverMutex: popoverMutex,
                  ),
                ))
            .toList();

        return Column(
          children: children,
        );
      },
    );
  }
}

class _SortItem extends StatelessWidget {
  final SortInfo sortInfo;
  final PopoverMutex popoverMutex;
  const _SortItem({
    required this.popoverMutex,
    required this.sortInfo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameButton = SortChoiceButton(
      text: sortInfo.fieldInfo.name,
      editable: false,
      onTap: () {},
    );
    final orderButton = _OrderButton(
      sortInfo: sortInfo,
      popoverMutex: popoverMutex,
    );

    final deleteButton = FlowyIconButton(
      width: 26,
      onPressed: () {
        context
            .read<SortEditorBloc>()
            .add(SortEditorEvent.deleteSort(sortInfo));
      },
      iconPadding: const EdgeInsets.all(5),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      icon: svgWidget(
        "home/close",
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    return Row(
      children: [
        SizedBox(height: 26, child: nameButton),
        const HSpace(6),
        SizedBox(height: 26, child: orderButton),
        const HSpace(16),
        deleteButton
      ],
    );
  }

  String textFromCondition(GridSortConditionPB condition) {
    switch (condition) {
      case GridSortConditionPB.Ascending:
        return LocaleKeys.grid_sort_ascending.tr();
      case GridSortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
    }
    return "";
  }
}

class _AddSortButton extends StatefulWidget {
  final String viewId;
  final GridFieldController fieldController;
  final PopoverMutex popoverMutex;
  const _AddSortButton({
    required this.viewId,
    required this.fieldController,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_AddSortButton> createState() => _AddSortButtonState();
}

class _AddSortButtonState extends State<_AddSortButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: _popoverController,
      mutex: widget.popoverMutex,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      offset: const Offset(0, 10),
      triggerActions: PopoverTriggerFlags.none,
      asBarrier: true,
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          disable: getCreatableSorts(widget.fieldController.fieldInfos).isEmpty,
          text: FlowyText.medium(LocaleKeys.grid_sort_addSort.tr()),
          onTap: () => _popoverController.show(),
          leftIcon: svgWidget(
            "home/add",
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      popupBuilder: (BuildContext context) {
        return GridCreateSortList(
          viewId: widget.viewId,
          fieldController: widget.fieldController,
          onClosed: () => _popoverController.close(),
        );
      },
    );
  }
}

class _DeleteSortButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const _DeleteSortButton({required this.popoverMutex, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            text: FlowyText.medium(LocaleKeys.grid_sort_deleteSort.tr()),
            onTap: () {
              context
                  .read<SortEditorBloc>()
                  .add(const SortEditorEvent.deleteAllSorts());
            },
            leftIcon: svgWidget(
              "editor/delete",
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

class _OrderButton extends StatefulWidget {
  final SortInfo sortInfo;
  final PopoverMutex popoverMutex;
  const _OrderButton({
    required this.popoverMutex,
    required this.sortInfo,
    Key? key,
  }) : super(key: key);

  @override
  _OrderButtonState createState() => _OrderButtonState();
}

class _OrderButtonState extends State<_OrderButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );

    return AppFlowyPopover(
      controller: popoverController,
      mutex: widget.popoverMutex,
      constraints: BoxConstraints.loose(const Size(340, 200)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (BuildContext popoverContext) {
        return OrderPanel(
          onCondition: (condition) {
            context
                .read<SortEditorBloc>()
                .add(SortEditorEvent.setCondition(widget.sortInfo, condition));
            popoverController.close();
          },
        );
      },
      child: SortChoiceButton(
        text: textFromCondition(widget.sortInfo.sortPB.condition),
        rightIcon: arrow,
        onTap: () => popoverController.show(),
      ),
    );
  }

  String textFromCondition(GridSortConditionPB condition) {
    switch (condition) {
      case GridSortConditionPB.Ascending:
        return LocaleKeys.grid_sort_ascending.tr();
      case GridSortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
    }
    return "";
  }
}
