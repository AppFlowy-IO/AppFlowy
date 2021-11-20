import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sizes.dart';

class TrashHeaderDelegate extends SliverPersistentHeaderDelegate {
  TrashHeaderDelegate();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return TrashHeader();
  }

  @override
  double get maxExtent => TrashSizes.headerHeight;

  @override
  double get minExtent => TrashSizes.headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class TrashHeaderItem {
  double width;
  String title;

  TrashHeaderItem({required this.width, required this.title});
}

class TrashHeader extends StatelessWidget {
  final List<TrashHeaderItem> items = [
    TrashHeaderItem(title: 'File name', width: TrashSizes.fileNameWidth),
    TrashHeaderItem(title: 'Last modified', width: TrashSizes.lashModifyWidth),
    TrashHeaderItem(title: 'Created', width: TrashSizes.createTimeWidth),
  ];

  TrashHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final headerItems = List<Widget>.empty(growable: true);
    items.asMap().forEach((index, item) {
      headerItems.add(
        SizedBox(
          width: item.width,
          child: FlowyText(
            item.title,
            fontSize: 12,
            color: theme.shader3,
          ),
        ),
      );
    });

    return Container(
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...headerItems,
        ],
      ),
    );
  }
}
