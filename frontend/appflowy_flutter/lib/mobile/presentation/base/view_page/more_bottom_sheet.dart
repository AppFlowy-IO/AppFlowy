import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileViewPageMoreBottomSheet extends StatelessWidget {
  const MobileViewPageMoreBottomSheet({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return ViewPageBottomSheet(
      view: view,
      onAction: (action) {
        switch (action) {
          case MobileViewBottomSheetBodyAction.duplicate:
            context.pop();
            context.read<ViewBloc>().add(const ViewEvent.duplicate());
            // show toast
            break;
          case MobileViewBottomSheetBodyAction.share:
            // unimplemented
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.delete:
            // pop to home page
            context
              ..pop()
              ..pop();
            context.read<ViewBloc>().add(const ViewEvent.delete());
            break;
          case MobileViewBottomSheetBodyAction.addToFavorites:
          case MobileViewBottomSheetBodyAction.removeFromFavorites:
            context.pop();
            context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));

            break;
          case MobileViewBottomSheetBodyAction.undo:
            EditorNotification.undo().post();
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.redo:
            EditorNotification.redo().post();
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.helpCenter:
            // unimplemented
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.rename:
            // no need to implement, rename is handled by the onRename callback.
            throw UnimplementedError();
        }
      },
      onRename: (name) {
        if (name != view.name) {
          context.read<ViewBloc>().add(ViewEvent.rename(name));
        }
        context.pop();
      },
    );
  }
}
