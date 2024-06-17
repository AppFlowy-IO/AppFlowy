import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum SpaceMoreActionType {
  delete,
  rename,
  changeIcon,
  collapseAllPages,
  divider,
  addNewSpace,
  manage,
}

extension ViewMoreActionTypeExtension on SpaceMoreActionType {
  String get name {
    switch (this) {
      case SpaceMoreActionType.delete:
        return LocaleKeys.space_delete.tr();
      case SpaceMoreActionType.rename:
        return LocaleKeys.space_rename.tr();
      case SpaceMoreActionType.changeIcon:
        return LocaleKeys.space_changeIcon.tr();
      case SpaceMoreActionType.collapseAllPages:
        return LocaleKeys.space_collapseAllSubPages.tr();
      case SpaceMoreActionType.addNewSpace:
        return LocaleKeys.space_addNewSpace.tr();
      case SpaceMoreActionType.manage:
        return LocaleKeys.space_manage.tr();
      case SpaceMoreActionType.divider:
        return '';
    }
  }

  Widget get leftIcon {
    switch (this) {
      case SpaceMoreActionType.delete:
        return const FlowySvg(FlowySvgs.trash_s, blendMode: null);
      case SpaceMoreActionType.rename:
        return const FlowySvg(FlowySvgs.view_item_rename_s);
      case SpaceMoreActionType.changeIcon:
        return const FlowySvg(FlowySvgs.change_icon_s);
      case SpaceMoreActionType.collapseAllPages:
        return const FlowySvg(FlowySvgs.collapse_all_page_s);
      case SpaceMoreActionType.addNewSpace:
        return const FlowySvg(FlowySvgs.space_add_s);
      case SpaceMoreActionType.manage:
        return const FlowySvg(FlowySvgs.space_manage_s);
      case SpaceMoreActionType.divider:
        return const SizedBox.shrink();
    }
  }

  Widget get rightIcon {
    switch (this) {
      case SpaceMoreActionType.changeIcon:
      case SpaceMoreActionType.rename:
      case SpaceMoreActionType.collapseAllPages:
      case SpaceMoreActionType.divider:
      case SpaceMoreActionType.delete:
      case SpaceMoreActionType.addNewSpace:
      case SpaceMoreActionType.manage:
        return const SizedBox.shrink();
    }
  }
}
