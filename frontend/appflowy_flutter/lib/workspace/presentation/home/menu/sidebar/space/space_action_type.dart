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
  duplicate,
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
      case SpaceMoreActionType.duplicate:
        return LocaleKeys.space_duplicate.tr();
      case SpaceMoreActionType.divider:
        return '';
    }
  }

  FlowySvgData get leftIconSvg {
    switch (this) {
      case SpaceMoreActionType.delete:
        return FlowySvgs.trash_s;
      case SpaceMoreActionType.rename:
        return FlowySvgs.view_item_rename_s;
      case SpaceMoreActionType.changeIcon:
        return FlowySvgs.change_icon_s;
      case SpaceMoreActionType.collapseAllPages:
        return FlowySvgs.collapse_all_page_s;
      case SpaceMoreActionType.addNewSpace:
        return FlowySvgs.space_add_s;
      case SpaceMoreActionType.manage:
        return FlowySvgs.space_manage_s;
      case SpaceMoreActionType.duplicate:
        return FlowySvgs.duplicate_s;
      case SpaceMoreActionType.divider:
        throw UnsupportedError('Divider does not have an icon');
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
      case SpaceMoreActionType.duplicate:
        return const SizedBox.shrink();
    }
  }
}
