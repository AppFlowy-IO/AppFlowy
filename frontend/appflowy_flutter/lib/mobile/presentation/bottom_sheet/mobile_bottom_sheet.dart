import 'package:appflowy/mobile/presentation/bottom_sheet/mobile_bottom_sheet_body.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/mobile_bottom_sheet_header.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/mobile_bottom_sheet_rename_widget.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
  });

  final ViewPB view;

  @override
  State<MobileViewItemBottomSheet> createState() =>
      _MobileViewItemBottomSheetState();
}

class _MobileViewItemBottomSheetState extends State<MobileViewItemBottomSheet> {
  MobileBottomSheetType type = MobileBottomSheetType.view;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // drag handler
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12.0),
          child: Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.0),
              color: Colors.grey,
            ),
          ),
        ),

        // header
        MobileBottomSheetHeader(
          showBackButton: type != MobileBottomSheetType.view,
          view: widget.view,
          onBack: () {
            setState(() {
              type = MobileBottomSheetType.view;
            });
          },
        ),
        const VSpace(8.0),
        const Divider(),

        // body
        _buildBody(),
        const VSpace(12.0),
      ],
    );
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
                Navigator.pop(context);
                break;
              case MobileViewItemBottomSheetBodyAction.share:
                // unimplemented
                Navigator.pop(context);
                break;
              case MobileViewItemBottomSheetBodyAction.delete:
                context.read<ViewBloc>().add(const ViewEvent.delete());
                Navigator.pop(context);
                break;
              case MobileViewItemBottomSheetBodyAction.addToFavorites:
              case MobileViewItemBottomSheetBodyAction.removeFromFavorites:
                context
                    .read<FavoriteBloc>()
                    .add(FavoriteEvent.toggle(widget.view));
                Navigator.pop(context);
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
