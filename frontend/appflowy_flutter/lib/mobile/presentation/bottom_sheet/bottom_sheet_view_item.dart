import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum MobileBottomSheetType {
  view,
  rename,
}

class MobileViewItemBottomSheet extends StatefulWidget {
  const MobileViewItemBottomSheet({
    super.key,
    required this.view,
    required this.actions,
    this.defaultType = MobileBottomSheetType.view,
  });

  final ViewPB view;
  final MobileBottomSheetType defaultType;
  final List<MobileViewItemBottomSheetBodyAction> actions;

  @override
  State<MobileViewItemBottomSheet> createState() =>
      _MobileViewItemBottomSheetState();
}

class _MobileViewItemBottomSheetState extends State<MobileViewItemBottomSheet> {
  MobileBottomSheetType type = MobileBottomSheetType.view;
  final fToast = FToast();

  @override
  void initState() {
    super.initState();

    type = widget.defaultType;
    fToast.init(AppGlobals.context);
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MobileBottomSheetType.view:
        return MobileViewItemBottomSheetBody(
          actions: widget.actions,
          isFavorite: widget.view.isFavorite,
          onAction: (action) {
            switch (action) {
              case MobileViewItemBottomSheetBodyAction.rename:
                setState(() {
                  type = MobileBottomSheetType.rename;
                });
                break;
              case MobileViewItemBottomSheetBodyAction.duplicate:
                Navigator.pop(context);
                context.read<ViewBloc>().add(const ViewEvent.duplicate());
                showToastNotification(
                  context,
                  message: LocaleKeys.button_duplicateSuccessfully.tr(),
                );
                break;
              case MobileViewItemBottomSheetBodyAction.share:
                // unimplemented
                Navigator.pop(context);
                break;
              case MobileViewItemBottomSheetBodyAction.delete:
                Navigator.pop(context);
                context.read<ViewBloc>().add(const ViewEvent.delete());
                break;
              case MobileViewItemBottomSheetBodyAction.addToFavorites:
              case MobileViewItemBottomSheetBodyAction.removeFromFavorites:
                Navigator.pop(context);
                context
                    .read<FavoriteBloc>()
                    .add(FavoriteEvent.toggle(widget.view));
                showToastNotification(
                  context,
                  message: !widget.view.isFavorite
                      ? LocaleKeys.button_favoriteSuccessfully.tr()
                      : LocaleKeys.button_unfavoriteSuccessfully.tr(),
                );
                break;
              case MobileViewItemBottomSheetBodyAction.removeFromRecent:
                _removeFromRecent(context);
                break;
              case MobileViewItemBottomSheetBodyAction.divider:
                break;
            }
          },
        );
      case MobileBottomSheetType.rename:
        return MobileBottomSheetRenameWidget(
          name: widget.view.name,
          onRename: (name) {
            if (name != widget.view.name) {
              context.read<ViewBloc>().add(ViewEvent.rename(name));
            }
            Navigator.pop(context);
          },
        );
    }
  }

  Future<void> _removeFromRecent(BuildContext context) async {
    final viewId = context.read<ViewBloc>().view.id;
    final recentViewsBloc = context.read<RecentViewsBloc>();
    Navigator.pop(context);

    await _showConfirmDialog(
      onDelete: () {
        recentViewsBloc.add(RecentViewsEvent.removeRecentViews([viewId]));
      },
    );
  }

  Future<void> _showConfirmDialog({required VoidCallback onDelete}) async {
    await showFlowyCupertinoConfirmDialog(
      title: LocaleKeys.sideBar_removePageFromRecent.tr(),
      leftButton: FlowyText(
        LocaleKeys.button_cancel.tr(),
        fontSize: 17.0,
        figmaLineHeight: 24.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF007AFF),
      ),
      rightButton: FlowyText(
        LocaleKeys.button_delete.tr(),
        fontSize: 17.0,
        figmaLineHeight: 24.0,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFFE0220),
      ),
      onRightButtonPressed: (context) {
        onDelete();

        Navigator.pop(context);

        showToastNotification(
          context,
          message: LocaleKeys.sideBar_removeSuccess.tr(),
        );
      },
    );
  }
}
