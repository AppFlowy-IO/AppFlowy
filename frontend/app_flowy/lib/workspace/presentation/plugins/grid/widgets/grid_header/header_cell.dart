import 'package:app_flowy/workspace/presentation/plugins/grid/grid_sizes.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

class HeaderCell extends StatelessWidget {
  final Field field;
  const HeaderCell(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      field.name,
      style: const TextStyle(fontSize: 15.0, color: Colors.black),
    );
  }
}

class HeaderCellContainer extends StatelessWidget {
  final HeaderCell child;
  final double width;
  const HeaderCellContainer({Key? key, required this.child, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26, width: 0.5),
          color: GridHeaderConstants.backgroundColor,
        ),
        padding: EdgeInsets.symmetric(vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
        child: child,
      ),
    );
  }
}

class HeaderCellLeading extends StatelessWidget {
  const HeaderCellLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GridSize.firstHeaderPadding,
      color: GridHeaderConstants.backgroundColor,
    );
  }
}
