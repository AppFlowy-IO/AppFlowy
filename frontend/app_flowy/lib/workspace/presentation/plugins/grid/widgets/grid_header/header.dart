import 'package:app_flowy/workspace/presentation/plugins/grid/grid_sizes.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';

import 'header_cell.dart';

class GridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Field> fields;

  GridHeaderDelegate(this.fields);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GridHeader(fields: fields);
  }

  @override
  double get maxExtent => GridSize.headerHeight;

  @override
  double get minExtent => GridSize.headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is GridHeaderDelegate) {
      return fields != oldDelegate.fields;
    }
    return false;
  }
}

class GridHeader extends StatelessWidget {
  final List<Field> fields;

  const GridHeader({required this.fields, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headers = List<Widget>.empty(growable: true);
    fields.asMap().forEach((index, field) {
      final header = HeaderCellContainer(
        width: field.width.toDouble(),
        child: HeaderCell(
          field,
        ),
      );

      //
      headers.add(header);
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeaderCellLeading(),
        ...headers,
      ],
    );
  }
}
