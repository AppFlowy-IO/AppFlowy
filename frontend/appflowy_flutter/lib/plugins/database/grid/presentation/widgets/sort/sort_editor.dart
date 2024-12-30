import 'dart:io';

import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/sort_entities.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_sort_list.dart';
import 'order_panel.dart';
import 'sort_choice_button.dart';

class SortEditor extends StatefulWidget {
  const SortEditor({super.key});

  @override
  State<SortEditor> createState() => _SortEditorState();
}

class _SortEditorState extends State<SortEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) => context
              .read<SortEditorBloc>()
              .add(SortEditorEvent.reorderSort(oldIndex, newIndex)),
          itemCount: state.sorts.length,
          itemBuilder: (context, index) => DatabaseSortItem(
            key: ValueKey(state.sorts[index].sortId),
            index: index,
            sort: state.sorts[index],
            popoverMutex: popoverMutex,
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
                  disable: state.creatableFields.isEmpty,
                  popoverMutex: popoverMutex,
                ),
              ),
              const HSpace(6),
              Flexible(
                child: DeleteAllSortsButton(
                  popoverMutex: popoverMutex,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DatabaseSortItem extends StatelessWidget {
  const DatabaseSortItem({
    super.key,
    required this.index,
    required this.popoverMutex,
    required this.sort,
  });

  final int index;
  final PopoverMutex popoverMutex;
  final DatabaseSort sort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: Platform.isWindows
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.grab,
              child: SizedBox(
                width: 14 + 12,
                height: 14,
                child: FlowySvg(
                  FlowySvgs.drag_element_s,
                  size: const Size.square(14),
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: SizedBox(
              height: 26,
              child: BlocSelector<SortEditorBloc, SortEditorState, FieldInfo?>(
                selector: (state) => state.allFields.firstWhereOrNull(
                  (field) => field.id == sort.fieldId,
                ),
                builder: (context, field) {
                  return SortChoiceButton(
                    text: field?.name ?? "",
                    editable: false,
                  );
                },
              ),
            ),
          ),
          const HSpace(6),
          Flexible(
            fit: FlexFit.tight,
            child: SizedBox(
              height: 26,
              child: SortConditionButton(
                sort: sort,
                popoverMutex: popoverMutex,
              ),
            ),
          ),
          const HSpace(6),
          FlowyIconButton(
            width: 26,
            onPressed: () {
              context
                  .read<SortEditorBloc>()
                  .add(SortEditorEvent.deleteSort(sort.sortId));
              PopoverContainer.of(context).close();
            },
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            icon: FlowySvg(
              FlowySvgs.trash_m,
              color: Theme.of(context).iconTheme.color,
              size: const Size.square(16),
            ),
          ),
        ],
      ),
    );
  }
}

extension SortConditionExtension on SortConditionPB {
  String get title {
    return switch (this) {
      SortConditionPB.Ascending => LocaleKeys.grid_sort_ascending.tr(),
      SortConditionPB.Descending => LocaleKeys.grid_sort_descending.tr(),
      _ => throw UnimplementedError(),
    };
  }
}

class DatabaseAddSortButton extends StatefulWidget {
  const DatabaseAddSortButton({
    super.key,
    required this.disable,
    required this.popoverMutex,
  });

  final bool disable;
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
      offset: const Offset(-6, 8),
      triggerActions: PopoverTriggerFlags.none,
      asBarrier: true,
      popupBuilder: (popoverContext) {
        return BlocProvider.value(
          value: context.read<SortEditorBloc>(),
          child: CreateDatabaseViewSortList(
            onTap: () => _popoverController.close(),
          ),
        );
      },
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).greyHover,
          disable: widget.disable,
          text: FlowyText(LocaleKeys.grid_sort_addSort.tr()),
          onTap: () => _popoverController.show(),
          leftIcon: const FlowySvg(FlowySvgs.add_s),
        ),
      ),
    );
  }
}

class DeleteAllSortsButton extends StatelessWidget {
  const DeleteAllSortsButton({super.key, required this.popoverMutex});

  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SortEditorBloc, SortEditorState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            text: FlowyText(LocaleKeys.grid_sort_deleteAllSorts.tr()),
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

class SortConditionButton extends StatefulWidget {
  const SortConditionButton({
    super.key,
    required this.popoverMutex,
    required this.sort,
  });

  final PopoverMutex popoverMutex;
  final DatabaseSort sort;

  @override
  State<SortConditionButton> createState() => _SortConditionButtonState();
}

class _SortConditionButtonState extends State<SortConditionButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      mutex: widget.popoverMutex,
      constraints: BoxConstraints.loose(const Size(340, 200)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (BuildContext popoverContext) {
        return OrderPanel(
          onCondition: (condition) {
            context.read<SortEditorBloc>().add(
                  SortEditorEvent.editSort(
                    sortId: widget.sort.sortId,
                    condition: condition,
                  ),
                );
            popoverController.close();
          },
        );
      },
      child: SortChoiceButton(
        text: widget.sort.condition.title,
        rightIcon: FlowySvg(
          FlowySvgs.arrow_down_s,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: () => popoverController.show(),
      ),
    );
  }
}
