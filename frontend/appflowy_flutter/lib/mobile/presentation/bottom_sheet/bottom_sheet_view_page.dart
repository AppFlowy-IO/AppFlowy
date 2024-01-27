import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum MobileViewBottomSheetBodyAction {
  undo,
  redo,
  share,
  rename,
  duplicate,
  delete,
  addToFavorites,
  removeFromFavorites,
  helpCenter;
}

typedef MobileViewBottomSheetBodyActionCallback = void Function(
  MobileViewBottomSheetBodyAction action,
);

class ViewPageBottomSheet extends StatefulWidget {
  const ViewPageBottomSheet({
    super.key,
    required this.view,
    required this.onAction,
    required this.onRename,
  });

  final ViewPB view;
  final MobileViewBottomSheetBodyActionCallback onAction;
  final void Function(String name) onRename;

  @override
  State<ViewPageBottomSheet> createState() => _ViewPageBottomSheetState();
}

class _ViewPageBottomSheetState extends State<ViewPageBottomSheet> {
  MobileBottomSheetType type = MobileBottomSheetType.view;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MobileBottomSheetType.view:
        return MobileViewBottomSheetBody(
          view: widget.view,
          onAction: (action) {
            switch (action) {
              case MobileViewBottomSheetBodyAction.rename:
                setState(() {
                  type = MobileBottomSheetType.rename;
                });
                break;
              default:
                widget.onAction(action);
            }
          },
        );

      case MobileBottomSheetType.rename:
        return MobileBottomSheetRenameWidget(
          name: widget.view.name,
          onRename: (name) {
            widget.onRename(name);
          },
        );
    }
  }
}

class MobileViewBottomSheetBody extends StatelessWidget {
  const MobileViewBottomSheetBody({
    super.key,
    required this.view,
    required this.onAction,
  });

  final ViewPB view;
  final MobileViewBottomSheetBodyActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isFavorite = view.isFavorite;
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
            MobileViewBottomSheetBodyAction.rename,
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
                ? MobileViewBottomSheetBodyAction.removeFromFavorites
                : MobileViewBottomSheetBodyAction.addToFavorites,
          ),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.button_duplicate.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.m_duplicate_s,
          ),
          showTopBorder: false,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.duplicate,
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
            MobileViewBottomSheetBodyAction.delete,
          ),
        ),
      ],
    );
  }
}
