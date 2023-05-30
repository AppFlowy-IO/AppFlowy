import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../../../grid/presentation/widgets/header/type_option/select_option_editor.dart';
import 'checklist_cell_editor_bloc.dart';
import 'checklist_progress_bar.dart';

class GridChecklistCellEditor extends StatefulWidget {
  final ChecklistCellController cellController;
  const GridChecklistCellEditor({required this.cellController, Key? key})
      : super(key: key);

  @override
  State<GridChecklistCellEditor> createState() =>
      _GridChecklistCellEditorState();
}

class _GridChecklistCellEditorState extends State<GridChecklistCellEditor> {
  late ChecklistCellEditorBloc bloc;
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    bloc = ChecklistCellEditorBloc(cellController: widget.cellController);
    bloc.add(const ChecklistCellEditorEvent.initial());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChecklistCellEditorBloc, ChecklistCellEditorState>(
        builder: (context, state) {
          final List<Widget> slivers = [
            const SliverChecklistProgressBar(),
            SliverToBoxAdapter(
              child: ListView.separated(
                controller: ScrollController(),
                shrinkWrap: true,
                itemCount: state.allOptions.length,
                itemBuilder: (BuildContext context, int index) {
                  return _ChecklistOptionCell(
                    option: state.allOptions[index],
                    popoverMutex: popoverMutex,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return VSpace(GridSize.typeOptionSeparatorHeight);
                },
              ),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: slivers,
                controller: ScrollController(),
                physics: StyledScrollPhysics(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistOptionCell extends StatefulWidget {
  final ChecklistSelectOption option;
  final PopoverMutex popoverMutex;
  const _ChecklistOptionCell({
    required this.option,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_ChecklistOptionCell> createState() => _ChecklistOptionCellState();
}

class _ChecklistOptionCellState extends State<_ChecklistOptionCell> {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.option.isSelected
        ? svgWidget('editor/editor_check')
        : svgWidget('editor/editor_uncheck');
    return _wrapPopover(
      SizedBox(
        height: GridSize.popoverItemHeight,
        child: Row(
          children: [
            Expanded(
              child: FlowyButton(
                hoverColor: AFThemeExtension.of(context).lightGreyHover,
                text: FlowyText(
                  widget.option.data.name,
                  color: AFThemeExtension.of(context).textColor,
                ),
                leftIcon: icon,
                onTap: () => context
                    .read<ChecklistCellEditorBloc>()
                    .add(ChecklistCellEditorEvent.selectOption(widget.option)),
              ),
            ),
            _disclosureButton(),
          ],
        ),
      ),
    );
  }

  Widget _disclosureButton() {
    return FlowyIconButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      onPressed: () => _popoverController.show(),
      iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      icon: svgWidget(
        "editor/details",
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }

  Widget _wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: _popoverController,
      offset: const Offset(8, 0),
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      mutex: widget.popoverMutex,
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionTypeOptionEditor(
          option: widget.option.data,
          onDeleted: () {
            context.read<ChecklistCellEditorBloc>().add(
                  ChecklistCellEditorEvent.deleteOption(widget.option.data),
                );

            _popoverController.close();
          },
          onUpdated: (updatedOption) {
            context.read<ChecklistCellEditorBloc>().add(
                  ChecklistCellEditorEvent.updateOption(updatedOption),
                );
          },
          showOptions: false,
          autoFocus: false,
          // Use ValueKey to refresh the UI, otherwise, it will remain the old value.
          key: ValueKey(
            widget.option.data.id,
          ),
        );
      },
    );
  }
}
