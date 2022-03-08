import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';

import '../content/cell_decoration.dart';

class GridFooter extends StatelessWidget {
  final VoidCallback? onAddRow;
  const GridFooter({Key? key, required this.onAddRow}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: GridSize.footerHeight,
        child: Row(
          children: [
            AddRowButton(onTap: onAddRow),
          ],
        ),
      ),
    );
  }
}

class AddRowButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AddRowButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: MouseHoverBuilder(
        builder: (_, isHovered) => Container(
          width: GridSize.startHeaderPadding,
          height: GridSize.footerHeight,
          decoration: CellDecoration.box(
            color: isHovered ? Colors.red.withOpacity(.1) : Colors.white,
          ),
          child: const Icon(Icons.add, size: 16),
        ),
      ),
    );
  }
}
