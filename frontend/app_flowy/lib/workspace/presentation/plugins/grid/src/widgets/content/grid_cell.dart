import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';

import 'cell_decoration.dart';
// ignore: import_of_legacy_library_into_null_safe

/// The interface of base cell.
abstract class GridCellWidget extends StatelessWidget {
  final canSelect = true;

  const GridCellWidget({Key? key}) : super(key: key);
}

class GridTextCell extends GridCellWidget {
  final String content;
  const GridTextCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class DateCell extends GridCellWidget {
  final String content;
  const DateCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class NumberCell extends GridCellWidget {
  final String content;
  const NumberCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class SingleSelectCell extends GridCellWidget {
  final String content;
  const SingleSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class MultiSelectCell extends GridCellWidget {
  final String content;
  const MultiSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class BlankCell extends GridCellWidget {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class RowLeading extends StatelessWidget {
  const RowLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return Expanded(
    //   child: Container(
    //     color: Colors.white10,
    //     width: GridSize.firstHeaderPadding,
    //   ),
    // );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: MouseHoverBuilder(
        builder: (_, isHovered) => Container(
          width: GridSize.firstHeaderPadding,
          decoration: CellDecoration.box(
            color: isHovered ? Colors.red.withOpacity(.1) : Colors.white,
          ),
          padding: EdgeInsets.symmetric(vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
        ),
      ),
    );
  }
}
