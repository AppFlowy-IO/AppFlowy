import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum ViewMoreActionType {
  delete,
  favorite,
  unFavorite,
  duplicate,
  copyLink, // not supported yet.
  rename,
  moveTo,
  openInNewTab,
  changeIcon,
  collapseAllPages, // including sub pages
  divider,
  lastModified,
  created,
}

extension ViewMoreActionTypeExtension on ViewMoreActionType {
  String get name {
    switch (this) {
      case ViewMoreActionType.delete:
        return LocaleKeys.disclosureAction_delete.tr();
      case ViewMoreActionType.favorite:
        return LocaleKeys.disclosureAction_favorite.tr();
      case ViewMoreActionType.unFavorite:
        return LocaleKeys.disclosureAction_unfavorite.tr();
      case ViewMoreActionType.duplicate:
        return LocaleKeys.disclosureAction_duplicate.tr();
      case ViewMoreActionType.copyLink:
        return LocaleKeys.disclosureAction_copyLink.tr();
      case ViewMoreActionType.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case ViewMoreActionType.moveTo:
        return LocaleKeys.disclosureAction_moveTo.tr();
      case ViewMoreActionType.openInNewTab:
        return LocaleKeys.disclosureAction_openNewTab.tr();
      case ViewMoreActionType.changeIcon:
        return LocaleKeys.disclosureAction_changeIcon.tr();
      case ViewMoreActionType.collapseAllPages:
        return LocaleKeys.disclosureAction_collapseAllPages.tr();
      case ViewMoreActionType.divider:
      case ViewMoreActionType.lastModified:
      case ViewMoreActionType.created:
        return '';
    }
  }

  FlowySvgData get leftIconSvg {
    switch (this) {
      case ViewMoreActionType.delete:
        return FlowySvgs.trash_s;
      case ViewMoreActionType.favorite:
        return FlowySvgs.favorite_s;
      case ViewMoreActionType.unFavorite:
        return FlowySvgs.unfavorite_s;
      case ViewMoreActionType.duplicate:
        return FlowySvgs.duplicate_s;
      case ViewMoreActionType.rename:
        return FlowySvgs.view_item_rename_s;
      case ViewMoreActionType.moveTo:
        return FlowySvgs.move_to_s;
      case ViewMoreActionType.openInNewTab:
        return FlowySvgs.view_item_open_in_new_tab_s;
      case ViewMoreActionType.changeIcon:
        return FlowySvgs.change_icon_s;
      case ViewMoreActionType.collapseAllPages:
        return FlowySvgs.collapse_all_page_s;
      case ViewMoreActionType.divider:
      case ViewMoreActionType.lastModified:
      case ViewMoreActionType.copyLink:
      case ViewMoreActionType.created:
        throw UnsupportedError('No left icon for $this');
    }
  }

  Widget get rightIcon {
    switch (this) {
      case ViewMoreActionType.changeIcon:
      case ViewMoreActionType.moveTo:
      case ViewMoreActionType.favorite:
      case ViewMoreActionType.unFavorite:
      case ViewMoreActionType.duplicate:
      case ViewMoreActionType.copyLink:
      case ViewMoreActionType.rename:
      case ViewMoreActionType.openInNewTab:
      case ViewMoreActionType.collapseAllPages:
      case ViewMoreActionType.divider:
      case ViewMoreActionType.delete:
      case ViewMoreActionType.lastModified:
      case ViewMoreActionType.created:
        return const SizedBox.shrink();
    }
  }
}
