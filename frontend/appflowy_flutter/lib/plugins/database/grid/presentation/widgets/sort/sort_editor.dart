import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/sort/util.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import 'create_sort_list.dart';
import 'order_panel.dart';
import 'sort_choice_button.dart';
import 'sort_info.dart';

class SortEditor extends StatefulWidget {
  const SortEditor({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.sortInfos,
  });

  final String viewId;
  final FieldController fieldController;
  final List<SortInfo> sortInfos;

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
          final sortInfos = state.sortInfos;

          return ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) => context
                .read<SortEditorBloc>()
                .add(SortEditorEvent.reorderSort(oldIndex, newIndex)),
            itemCount: state.sortInfos.length,
            itemBuilder: (context, index) => Padding(
              key: ValueKey(sortInfos[index].sortId),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: DatabaseSortItem(
                index: index,
                sortInfo: sortInfos[index],
                popoverMutex: popoverMutex,
              ),
            ),
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  BlocProvider.value(
                    value: context.read<SortEditorBloc>(),
                    child: child,
                  ),
                  MouseRegion(
                    cursor: Platform.isWindows
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.grabbing,
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            footer: Row(
              children: [
                Flexible(
                  child: DatabaseAddSortButton(
                    viewId: widget.viewId,
                    fieldController: widget.fieldController,
                    popoverMutex: popoverMutex,
                  ),
                ),
                const HSpace(6),
                Flexible(
                  child: DatabaseDeleteSortButton(
                    popoverMutex: popoverMutex,
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

class DatabaseSortItem extends StatelessWidget {
  const DatabaseSortItem({
    super.key,
    required this.index,
    required this.popoverMutex,
    required this.sortInfo,
  });

  final int index;
  final PopoverMutex popoverMutex;
  final SortInfo sortInfo;

  @override
  Widget build(BuildContext context) {
    final deleteButton = FlowyIconButton(
      width: 26,
      onPressed: () => context
          .read<SortEditorBloc>()
          .add(SortEditorEvent.deleteSort(sortInfo)),
      iconPadding: const EdgeInsets.all(5),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      icon:
          FlowySvg(FlowySvgs.close_s, color: Theme.of(context).iconTheme.color),
    );

    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: MouseRegion(
            cursor: Platform.isWindows
                ? SystemMouseCursors.click
                : SystemMouseCursors.grab,
            child: SizedBox(
              width: 14,
              height: 14,
              child: FlowySvg(
                FlowySvgs.drag_element_s,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ),
        const HSpace(6),
        SizedBox(
          height: 26,
          child: SortChoiceButton(
            text: sortInfo.fieldInfo.name,
            editable: false,
          ),
        ),
        const HSpace(6),
        SizedBox(
          height: 26,
          child: DatabaseSortItemOrderButton(
            sortInfo: sortInfo,
            popoverMutex: popoverMutex,
          ),
        ),
        const Spacer(),
        const HSpace(6),
        deleteButton,
      ],
    );
  }
}

extension SortConditionExtension on SortConditionPB {
  String get title {
    switch (this) {
      case SortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
      default:
        return LocaleKeys.grid_sort_ascending.tr();
    }
  }
}

class DatabaseAddSortButton extends StatefulWidget {
  const DatabaseAddSortButton({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.popoverMutex,
  });

  final String viewId;
  final FieldController fieldController;
  final PopoverMutex popoverMutex;

  @override
  State<DatabaseAddSortButton> createState() => _DatabaseAddSortButtonState();
}

class _DatabaseAddSortButtonState extends State<DatabaseAddSortButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: _popoverController,
      mutex: widget.popoverMutex,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      offset: const Offset(0, 8),
      triggerActions: PopoverTriggerFlags.none,
      asBarrier: true,
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).greyHover,
          disable: getCreatableSorts(widget.fieldController.fieldInfos).isEmpty,
          text: FlowyText.medium(LocaleKeys.grid_sort_addSort.tr()),
          onTap: () => _popoverController.show(),
          leftIcon: const FlowySvg(FlowySvgs.add_s),
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

class DatabaseDeleteSortButton extends StatelessWidget {
  const DatabaseDeleteSortButton({super.key, required this.popoverMutex});

  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            text: FlowyText.medium(LocaleKeys.grid_sort_deleteAllSorts.tr()),
            onTap: () {
              context
                  .read<SortEditorBloc>()
                  .add(const SortEditorEvent.deleteAllSorts());
              PopoverContainer.of(context).close();
            },
            leftIcon: const FlowySvg(FlowySvgs.delete_s),
          ),
        );
      },
    );
  }
}

class DatabaseSortItemOrderButton extends StatefulWidget {
  const DatabaseSortItemOrderButton({
    super.key,
    required this.popoverMutex,
    required this.sortInfo,
  });

  final PopoverMutex popoverMutex;
  final SortInfo sortInfo;

  @override
  State<DatabaseSortItemOrderButton> createState() =>
      _DatabaseSortItemOrderButtonState();
}

class _DatabaseSortItemOrderButtonState
    extends State<DatabaseSortItemOrderButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: const FlowySvg(FlowySvgs.arrow_left_s),
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
        text: widget.sortInfo.sortPB.condition.title,
        rightIcon: arrow,
        onTap: () => popoverController.show(),
      ),
    );
  }
}
