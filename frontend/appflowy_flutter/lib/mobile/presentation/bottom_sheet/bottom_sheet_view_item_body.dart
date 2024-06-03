import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
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
        return FlowyOptionTile.text(
          text: LocaleKeys.button_rename.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.view_item_rename_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.rename,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.duplicate:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_duplicate.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.duplicate_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.duplicate,
          ),
        );

      case MobileViewItemBottomSheetBodyAction.share:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_share.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.share_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.share,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.delete:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.delete_s,
            size: const Size.square(18),
            color: Theme.of(context).colorScheme.error,
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.delete,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.addToFavorites:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_addToFavorites.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.favorite_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.addToFavorites,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.removeFromFavorites:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_removeFromFavorites.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.favorite_section_remove_from_favorite_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.removeFromFavorites,
          ),
        );
      case MobileViewItemBottomSheetBodyAction.removeFromRecent:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_removeFromRecent.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.remove_from_recent_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.removeFromRecent,
          ),
        );

      case MobileViewItemBottomSheetBodyAction.divider:
        return const Divider(height: 0.5);
    }
  }
}
