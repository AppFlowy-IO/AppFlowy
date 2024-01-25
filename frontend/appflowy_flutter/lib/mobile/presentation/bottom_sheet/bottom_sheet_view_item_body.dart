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
}

class MobileViewItemBottomSheetBody extends StatelessWidget {
  const MobileViewItemBottomSheetBody({
    super.key,
    this.isFavorite = false,
    required this.onAction,
  });

  final bool isFavorite;
  final void Function(MobileViewItemBottomSheetBodyAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowyOptionTile.text(
          text: LocaleKeys.button_rename.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.m_rename_s,
          ),
          showTopBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.rename,
          ),
        ),
        FlowyOptionTile.text(
          text: isFavorite
              ? LocaleKeys.button_removeFromFavorites.tr()
              : LocaleKeys.button_addToFavorites.tr(),
          leftIcon: FlowySvg(
            size: const Size(20, 20),
            isFavorite
                ? FlowySvgs.m_favorite_selected_lg
                : FlowySvgs.m_favorite_unselected_lg,
            color: isFavorite ? Colors.yellow : null,
          ),
          showTopBorder: false,
          onTap: () => onAction(
            isFavorite
                ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
                : MobileViewItemBottomSheetBodyAction.addToFavorites,
          ),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.button_duplicate.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.m_duplicate_s,
          ),
          showTopBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.duplicate,
          ),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.m_delete_s,
            color: Theme.of(context).colorScheme.error,
          ),
          showTopBorder: false,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.delete,
          ),
        ),
      ],
    );
  }
}
