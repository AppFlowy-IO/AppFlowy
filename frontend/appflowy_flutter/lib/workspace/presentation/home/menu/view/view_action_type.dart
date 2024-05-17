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
        return '';
    }
  }

  Widget get leftIcon {
    switch (this) {
      case ViewMoreActionType.delete:
        return const FlowySvg(FlowySvgs.trash_s, blendMode: null);
      case ViewMoreActionType.favorite:
        return const FlowySvg(FlowySvgs.favorite_s);
      case ViewMoreActionType.unFavorite:
        return const FlowySvg(FlowySvgs.unfavorite_s);
      case ViewMoreActionType.duplicate:
        return const FlowySvg(FlowySvgs.duplicate_s);
      case ViewMoreActionType.copyLink:
        return const Icon(Icons.copy);
      case ViewMoreActionType.rename:
        return const FlowySvg(FlowySvgs.view_item_rename_s);
      case ViewMoreActionType.moveTo:
        return const FlowySvg(FlowySvgs.move_to_s);
      case ViewMoreActionType.openInNewTab:
        return const FlowySvg(FlowySvgs.view_item_open_in_new_tab_s);
      case ViewMoreActionType.changeIcon:
        return const FlowySvg(FlowySvgs.change_icon_s);
      case ViewMoreActionType.collapseAllPages:
        return const FlowySvg(FlowySvgs.collapse_all_page_s);
      case ViewMoreActionType.divider:
      case ViewMoreActionType.lastModified:
        return const SizedBox.shrink();
    }
  }

  Widget get rightIcon {
    switch (this) {
      case ViewMoreActionType.changeIcon:
      case ViewMoreActionType.moveTo:
        return const FlowySvg(FlowySvgs.view_item_right_arrow_s);
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
        return const SizedBox.shrink();
    }
  }
}
