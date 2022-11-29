import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/checklist_cell_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/checklist_cell/checklist_prograss_bar.dart';
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
          return CustomScrollView(
            shrinkWrap: true,
            slivers: slivers,
            controller: ScrollController(),
            physics: StyledScrollPhysics(),
          );
        },
      ),
    );
  }
}

class _ChecklistOptionCell extends StatelessWidget {
  final ChecklistSelectOption option;
  const _ChecklistOptionCell({
    required this.option,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(height: 20, width: 100, color: Colors.red);
  }
}
