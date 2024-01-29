import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/scalable_flowy_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum ViewMoreActionType {
  delete,
  favorite,
  unFavorite,
  duplicate,
  copyLink, // not supported yet.
  rename,
  moveTo, // not supported yet.
  openInNewTab,
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
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case ViewMoreActionType.delete:
        return const ScalableFlowySvg(FlowySvgs.delete_s);
      case ViewMoreActionType.favorite:
        return const ScalableFlowySvg(FlowySvgs.unfavorite_s);
      case ViewMoreActionType.unFavorite:
        return const ScalableFlowySvg(FlowySvgs.favorite_s);
      case ViewMoreActionType.duplicate:
        return const ScalableFlowySvg(FlowySvgs.copy_s);
      case ViewMoreActionType.copyLink:
        return const Icon(Icons.copy);
      case ViewMoreActionType.rename:
        return const ScalableFlowySvg(FlowySvgs.edit_s);
      case ViewMoreActionType.moveTo:
        return const Icon(Icons.move_to_inbox);
      case ViewMoreActionType.openInNewTab:
        return const ScalableFlowySvg(FlowySvgs.full_view_s);
    }
  }
}
