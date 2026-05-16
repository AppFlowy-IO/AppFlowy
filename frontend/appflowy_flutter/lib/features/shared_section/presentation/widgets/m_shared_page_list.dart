import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flutter/material.dart';

/// Shared pages on mobile
class MSharedPageList extends StatelessWidget {
  const MSharedPageList({
    super.key,
    required this.sharedPages,
    required this.onSelected,
  });

  final SharedPages sharedPages;
  final ViewItemOnSelected onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sharedPages.map((sharedPage) {
        final view = sharedPage.view;
        return MobileViewItem(
          key: ValueKey(view.id),
          spaceType: FolderSpaceType.public,
          isFirstChild: view.id == sharedPages.first.view.id,
          view: view,
          level: 0,
          isDraggable: false, // disable draggable for shared pages
          leftPadding: HomeSpaceViewSizes.leftPadding,
          isFeedback: false,
          onSelected: onSelected,
        );
      }).toList(),
    );
  }
}
