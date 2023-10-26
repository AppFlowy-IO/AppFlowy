import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_drag_handler.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_rename_widget.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_view_item_body.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_view_item_header.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart' hide WidgetBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum MobileBottomSheetType {
  view,
  rename,
}

class MobileViewItemBottomSheet extends StatefulWidget {
  const MobileViewItemBottomSheet({
    super.key,
    required this.view,
    this.defaultType = MobileBottomSheetType.view,
  });

  final ViewPB view;
  final MobileBottomSheetType defaultType;

  @override
  State<MobileViewItemBottomSheet> createState() =>
      _MobileViewItemBottomSheetState();
}

class _MobileViewItemBottomSheetState extends State<MobileViewItemBottomSheet> {
  MobileBottomSheetType type = MobileBottomSheetType.view;

  @override
  initState() {
    super.initState();

    type = widget.defaultType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // drag handler
        const MobileBottomSheetDragHandler(),

        // header
        _buildHeader(),
        const VSpace(8.0),
        const Divider(),

        // body
        _buildBody(),
        const VSpace(24.0),
      ],
    );
  }

  Widget _buildHeader() {
    switch (type) {
      case MobileBottomSheetType.view:
      case MobileBottomSheetType.rename:
        // header
        return MobileViewItemBottomSheetHeader(
          showBackButton: type != MobileBottomSheetType.view,
          view: widget.view,
          onBack: () {
            setState(() {
              type = MobileBottomSheetType.view;
            });
          },
        );
    }
  }

  Widget _buildBody() {
    switch (type) {
      case MobileBottomSheetType.view:
        return MobileViewItemBottomSheetBody(
          isFavorite: widget.view.isFavorite,
          onAction: (action) {
            switch (action) {
              case MobileViewItemBottomSheetBodyAction.rename:
                setState(() {
                  type = MobileBottomSheetType.rename;
                });
                break;
              case MobileViewItemBottomSheetBodyAction.duplicate:
                context.read<ViewBloc>().add(const ViewEvent.duplicate());
                context.pop();
                break;
              case MobileViewItemBottomSheetBodyAction.share:
                // unimplemented
                context.pop();
                break;
              case MobileViewItemBottomSheetBodyAction.delete:
                context.read<ViewBloc>().add(const ViewEvent.delete());
                context.pop();
                break;
              case MobileViewItemBottomSheetBodyAction.addToFavorites:
              case MobileViewItemBottomSheetBodyAction.removeFromFavorites:
                context
                    .read<FavoriteBloc>()
                    .add(FavoriteEvent.toggle(widget.view));
                context.pop();
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
            context.pop();
          },
        );
    }
  }
}
