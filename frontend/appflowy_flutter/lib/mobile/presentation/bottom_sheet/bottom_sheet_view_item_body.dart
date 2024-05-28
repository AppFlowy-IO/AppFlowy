import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum MobileViewItemBottomSheetBodyAction {
  rename,
  duplicate,
  share,
  delete,
  addToFavorites,
  removeFromFavorites,
  divider,
  removeFromRecent,
}

class MobileViewItemBottomSheetBody extends StatelessWidget {
  const MobileViewItemBottomSheetBody({
    super.key,
    this.isFavorite = false,
    required this.onAction,
    required this.actions,
  });

  final bool isFavorite;
  final void Function(MobileViewItemBottomSheetBodyAction action) onAction;
  final List<MobileViewItemBottomSheetBodyAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          actions.map((action) => _buildActionButton(context, action)).toList(),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    MobileViewItemBottomSheetBodyAction action,
  ) {
    switch (action) {
      case MobileViewItemBottomSheetBodyAction.rename:
        return MobileQuickActionButton(
          text: LocaleKeys.button_rename.tr(),
          icon: FlowySvgs.view_item_rename_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.rename,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.duplicate:
        return MobileQuickActionButton(
          text: LocaleKeys.button_duplicate.tr(),
          icon: FlowySvgs.duplicate_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.duplicate,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.share:
        return MobileQuickActionButton(
          text: LocaleKeys.button_share.tr(),
          icon: FlowySvgs.m_share_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.share,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.delete:
        return MobileQuickActionButton(
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          icon: FlowySvgs.m_delete_s,
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.delete,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.addToFavorites:
        return MobileQuickActionButton(
          text: LocaleKeys.button_addToFavorites.tr(),
          icon: FlowySvgs.favorite_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.addToFavorites,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.removeFromFavorites:
        return MobileQuickActionButton(
          text: LocaleKeys.button_removeFromFavorites.tr(),
          icon: FlowySvgs.favorite_section_remove_from_favorite_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.removeFromFavorites,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.removeFromRecent:
        return MobileQuickActionButton(
          text: LocaleKeys.button_removeFromRecent.tr(),
          icon: FlowySvgs.remove_from_recent_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.removeFromRecent,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.divider:
        return const Divider(height: 0.5);
    }
  }
}
