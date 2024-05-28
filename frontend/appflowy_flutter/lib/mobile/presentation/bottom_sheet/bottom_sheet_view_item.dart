import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();

    type = widget.defaultType;
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
                // unimplemented
                Navigator.pop(context);
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
}
