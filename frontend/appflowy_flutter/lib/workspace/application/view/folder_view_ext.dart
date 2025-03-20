import 'dart:convert';

import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';

extension FolderViewPBExtension on FolderViewPB {
  /// Get the space permission pb of the space.
  SpacePermissionPB get spacePermissionPB {
    if (isPrivate == true) {
      return SpacePermissionPB.PrivateSpace;
    }
    return SpacePermissionPB.PublicSpace;
  }

  /// Get the space permission of the space.
  SpacePermission get spacePermission {
    if (isPrivate == true) {
      return SpacePermission.private;
    }
    return SpacePermission.publicToAll;
  }

  /// Get all the published page recursively.
  List<FolderViewPB> get publishedPages {
    final result = <FolderViewPB>[];
    if (isPublished) {
      result.add(this);
    }
    if (children.isNotEmpty) {
      result.addAll(children.map((e) => e.publishedPages).toList().flattened);
    }
    return result;
  }

  /// Build the space icon svg of the space.
  FlowySvg? buildSpaceIconSvg(BuildContext context, {Size? size}) {
    try {
      if (extra.isEmpty) {
        return null;
      }

      final ext = jsonDecode(extra);
      final icon = ext[ViewExtKeys.spaceIconKey];
      final color = ext[ViewExtKeys.spaceIconColorKey];
      if (icon == null || color == null) {
        return null;
      }
      // before version 0.6.7
      if (icon.contains('space_icon')) {
        return FlowySvg(
          FlowySvgData('assets/flowy_icons/16x/$icon.svg'),
          color: Theme.of(context).colorScheme.surface,
        );
      }

      final values = icon.split('/');
      if (values.length != 2) {
        return null;
      }
      final groupName = values[0];
      final iconName = values[1];
      final svgString = kIconGroups
          ?.firstWhereOrNull(
            (group) => group.name == groupName,
          )
          ?.icons
          .firstWhereOrNull(
            (icon) => icon.name == iconName,
          )
          ?.content;
      if (svgString == null) {
        return null;
      }
      return FlowySvg.string(
        svgString,
        color: Theme.of(context).colorScheme.surface,
        size: size,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the space icon of the space.
  String? get spaceIcon {
    try {
      final ext = jsonDecode(extra);
      final icon = ext[ViewExtKeys.spaceIconKey];
      return icon;
    } catch (e) {
      return null;
    }
  }

  /// Get the space icon color of the space.
  String? get spaceIconColor {
    try {
      final ext = jsonDecode(extra);
      final color = ext[ViewExtKeys.spaceIconColorKey];
      return color;
    } catch (e) {
      return null;
    }
  }

  ViewPB get viewPB {
    final children = this.children.map((e) => e.viewPB).toList();
    return ViewPB(
      id: viewId,
      name: name,
      icon: icon,
      layout: layout,
      createTime: createdAt,
      lastEdited: lastEditedTime,
      extra: extra,
      childViews: children,
    );
  }
}

extension ListFolderViewPBExtension on List<FolderViewPB> {
  List<ViewPB> get viewPBs {
    return map((e) => e.viewPB).toList();
  }
}
