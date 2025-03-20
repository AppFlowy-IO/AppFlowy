import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/folder_view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FolderViews extends StatelessWidget {
  const FolderViews({
    super.key,
    required this.space,
    required this.isHovered,
    required this.isExpandedNotifier,
    required this.onSelected,
    this.rightIconsBuilder,
    this.disableSelectedStatus = false,
    this.onTertiarySelected,
    this.shouldIgnoreView,
  });

  final FolderViewPB space;
  final ValueNotifier<bool> isHovered;
  final PropertyValueNotifier<bool> isExpandedNotifier;
  final bool disableSelectedStatus;
  final FolderViewItemRightIconsBuilder? rightIconsBuilder;
  final FolderViewItemOnSelected onSelected;
  final FolderViewItemOnSelected? onTertiarySelected;
  final IgnoreFolderViewType Function(FolderViewPB view)? shouldIgnoreView;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: space.children
          .map(
            (view) => FolderViewItem(
              key: view.toValueKey(),
              spaceType: !space.isPrivate
                  ? FolderSpaceType.public
                  : FolderSpaceType.private,
              isFirstChild: view.viewId == space.children.first.viewId,
              view: view,
              level: 0,
              leftPadding: HomeSpaceViewSizes.leftPadding,
              isFeedback: false,
              isHovered: isHovered,
              enableRightClickContext: !disableSelectedStatus,
              disableSelectedStatus: disableSelectedStatus,
              isExpandedNotifier: isExpandedNotifier,
              rightIconsBuilder: rightIconsBuilder,
              onSelected: onSelected,
              onTertiarySelected: onTertiarySelected,
              shouldIgnoreView: shouldIgnoreView,
            ),
          )
          .toList(),
    );
  }
}

extension on FolderViewPB {
  ValueKey toValueKey() => ValueKey(hashCode);
}
