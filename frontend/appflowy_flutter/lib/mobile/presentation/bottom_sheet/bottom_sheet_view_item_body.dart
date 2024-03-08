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
        MobileQuickActionButton(
          text: LocaleKeys.button_rename.tr(),
          icon: FlowySvgs.m_rename_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.rename,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: isFavorite
              ? LocaleKeys.button_removeFromFavorites.tr()
              : LocaleKeys.button_addToFavorites.tr(),
          icon: isFavorite
              ? FlowySvgs.m_favorite_selected_lg
              : FlowySvgs.m_favorite_unselected_lg,
          iconColor: isFavorite ? Colors.yellow : null,
          onTap: () => onAction(
            isFavorite
                ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
                : MobileViewItemBottomSheetBodyAction.addToFavorites,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: LocaleKeys.button_duplicate.tr(),
          icon: FlowySvgs.m_duplicate_s,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.duplicate,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          icon: FlowySvgs.m_delete_s,
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => onAction(
            MobileViewItemBottomSheetBodyAction.delete,
          ),
        ),
        _divider(),
      ],
    );
  }

  Widget _divider() => const Divider(
        height: 8.5,
        thickness: 0.5,
      );
}
