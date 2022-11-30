import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/checklist_cell_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/checklist_cell/checklist_prograss_bar.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/type_option/select_option_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridChecklistCellEditor extends StatefulWidget {
  final GridChecklistCellController cellController;
  const GridChecklistCellEditor({required this.cellController, Key? key})
      : super(key: key);

  @override
  State<GridChecklistCellEditor> createState() =>
      _GridChecklistCellEditorState();
}

class _GridChecklistCellEditorState extends State<GridChecklistCellEditor> {
  late ChecklistCellEditorBloc bloc;

  @override
  void initState() {
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
            const SliverChecklistPrograssBar(),
            SliverToBoxAdapter(
                child: Container(color: Colors.red, height: 2, width: 2100)),
            SliverToBoxAdapter(
              child: ListView.separated(
                controller: ScrollController(),
                shrinkWrap: true,
                itemCount: state.allOptions.length,
                itemBuilder: (BuildContext context, int index) {
                  return _ChecklistOptionCell(option: state.allOptions[index]);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return VSpace(GridSize.typeOptionSeparatorHeight);
                },
              ),
            ),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: slivers,
              controller: ScrollController(),
              physics: StyledScrollPhysics(),
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistOptionCell extends StatefulWidget {
  final ChecklistSelectOption option;
  const _ChecklistOptionCell({
    required this.option,
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
        height: GridSize.typeOptionItemHeight,
        child: Row(
          children: [
            icon,
            const HSpace(6),
            FlowyText(widget.option.data.name),
            const Spacer(),
            _disclosureButton(),
          ],
        ),
      ),
    );
  }

  Widget _disclosureButton() {
    return FlowyIconButton(
      width: 20,
      onPressed: () => _popoverController.show(),
      hoverColor: Colors.transparent,
      iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      icon: svgWidget(
        "editor/details",
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: _popoverController,
      offset: const Offset(20, 0),
      asBarrier: true,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      child: child,
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionTypeOptionEditor(
          option: widget.option.data,
          onDeleted: () {},
          onUpdated: (updatedOption) {},
          key: ValueKey(
            widget.option.data.id,
          ), // Use ValueKey to refresh the UI, otherwise, it will remain the old value.
        );
      },
    );
  }
}
