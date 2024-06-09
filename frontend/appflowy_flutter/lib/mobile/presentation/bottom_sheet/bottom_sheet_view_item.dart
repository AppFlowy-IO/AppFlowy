import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
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

        fToast.showToast(
          child: const _RemoveToast(),
          positionedToastBuilder: (context, child) {
            return Positioned.fill(
              top: 450,
              child: child,
            );
          },
        );
      },
    );
  }

  Future<void> _showConfirmDialog({required VoidCallback onDelete}) async {
    await showFlowyCupertinoConfirmDialog(
      title: LocaleKeys.sideBar_removePageFromRecent.tr(),
      leftButton: FlowyText.regular(
        LocaleKeys.button_cancel.tr(),
        color: const Color(0xFF1456F0),
      ),
      rightButton: FlowyText.medium(
        LocaleKeys.button_delete.tr(),
        color: const Color(0xFFFE0220),
      ),
      onRightButtonPressed: (context) {
        onDelete();
        Navigator.pop(context);
      },
    );
  }
}

class _RemoveToast extends StatelessWidget {
  const _RemoveToast();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 13.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: const Color(0xE5171717),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlowySvg(
            FlowySvgs.success_s,
            blendMode: null,
          ),
          const HSpace(8.0),
          FlowyText.regular(
            LocaleKeys.sideBar_removeSuccess.tr(),
            fontSize: 16.0,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
