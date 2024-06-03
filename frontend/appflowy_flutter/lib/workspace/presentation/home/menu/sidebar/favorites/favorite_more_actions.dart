import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteMoreActions extends StatelessWidget {
  const FavoriteMoreActions({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.menuAppHeader_moreButtonToolTip.tr(),
      child: ViewMoreActionButton(
        view: view,
        spaceType: FolderSpaceType.favorite,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onAction: (action, _) {
          switch (action) {
            case ViewMoreActionType.favorite:
            case ViewMoreActionType.unFavorite:
              context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
              PopoverContainer.maybeOf(context)?.closeAll();
              break;
            case ViewMoreActionType.rename:
              NavigatorTextFieldDialog(
                title: LocaleKeys.disclosureAction_rename.tr(),
                autoSelectAllText: true,
                value: view.name,
                maxLength: 256,
                onConfirm: (newValue, _) {
                  // can not use bloc here because it has been disposed.
                  ViewBackendService.updateView(
                    viewId: view.id,
                    name: newValue,
                  );
                },
              ).show(context);
              PopoverContainer.maybeOf(context)?.closeAll();
              break;

            case ViewMoreActionType.openInNewTab:
              getIt<TabsBloc>().openTab(view);
              break;
            case ViewMoreActionType.delete:
            case ViewMoreActionType.duplicate:
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
      ),
    );
  }
}
