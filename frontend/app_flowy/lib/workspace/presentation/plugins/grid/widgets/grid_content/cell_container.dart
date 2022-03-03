import 'package:app_flowy/workspace/presentation/plugins/grid/grid_sizes.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';
import 'cell_decoration.dart';
import 'grid_cell.dart';

class CellContainer extends StatelessWidget {
  final GridCellWidget child;
  final double width;
  const CellContainer({Key? key, required this.child, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // context
        //     .read<HomeBloc>()
        //     .add(HomeEvent.setEditPannel(CellEditPannelContext()));
      },
      child: MouseHoverBuilder(
        builder: (_, isHovered) => Container(
          width: width,
          decoration: CellDecoration.box(
            color: isHovered ? Colors.red.withOpacity(.1) : Colors.transparent,
          ),
          padding: EdgeInsets.symmetric(vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
          child: child,
        ),
      ),
    );
  }
}
