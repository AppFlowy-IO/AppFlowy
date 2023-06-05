import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'sizes.dart';

class TrashHeaderDelegate extends SliverPersistentHeaderDelegate {
  TrashHeaderDelegate();

  @override
  Widget build(
    final BuildContext context,
    final double shrinkOffset,
    final bool overlapsContent,
  ) {
    return TrashHeader();
  }

  @override
  double get maxExtent => TrashSizes.headerHeight;

  @override
  double get minExtent => TrashSizes.headerHeight;

  @override
  bool shouldRebuild(covariant final SliverPersistentHeaderDelegate oldDelegate) {
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
    TrashHeaderItem(
      title: LocaleKeys.trash_pageHeader_fileName.tr(),
      width: TrashSizes.fileNameWidth,
    ),
    TrashHeaderItem(
      title: LocaleKeys.trash_pageHeader_lastModified.tr(),
      width: TrashSizes.lashModifyWidth,
    ),
    TrashHeaderItem(
      title: LocaleKeys.trash_pageHeader_created.tr(),
      width: TrashSizes.createTimeWidth,
    ),
  ];

  TrashHeader({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final headerItems = List<Widget>.empty(growable: true);
    items.asMap().forEach((final index, final item) {
      headerItems.add(
        SizedBox(
          width: item.width,
          child: FlowyText(
            item.title,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    });

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...headerItems,
        ],
      ),
    );
  }
}
