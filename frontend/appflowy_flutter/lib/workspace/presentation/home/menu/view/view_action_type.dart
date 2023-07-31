import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum ViewMoreActionType {
  delete,
  toggleFavorite, // not supported yet.
  duplicate,
  copyLink, // not supported yet.
  rename,
  moveTo, // not supported yet.
  openInNewTab,
}

extension ViewMoreActionTypeExtension on ViewMoreActionType {
  String name({bool? state}) {
    switch (this) {
      case ViewMoreActionType.delete:
        return LocaleKeys.disclosureAction_delete.tr();
      case ViewMoreActionType.toggleFavorite:
        if (state!) {
          return LocaleKeys.disclosureAction_favorite.tr();
        } else {
          return LocaleKeys.disclosureAction_unfavorite.tr();
        }
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
    }
  }

  Widget icon(Color iconColor, {bool? state}) {
    switch (this) {
      case ViewMoreActionType.delete:
        return const FlowySvg(name: 'editor/delete');
      case ViewMoreActionType.toggleFavorite:
        if (state!) {
          return const FlowySvg(name: 'home/favorite');
        } else {
          return const FlowySvg(name: 'home/unfavorite');
        }
      case ViewMoreActionType.duplicate:
        return const FlowySvg(name: 'editor/copy');
      case ViewMoreActionType.copyLink:
        return const Icon(Icons.copy);
      case ViewMoreActionType.rename:
        return const FlowySvg(name: 'editor/edit');
      case ViewMoreActionType.moveTo:
        return const Icon(Icons.move_to_inbox);
      case ViewMoreActionType.openInNewTab:
        return const FlowySvg(name: 'grid/expander');
    }
  }
}
