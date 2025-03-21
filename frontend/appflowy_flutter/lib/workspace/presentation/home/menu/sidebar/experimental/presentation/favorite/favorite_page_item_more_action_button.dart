import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/favorite/folder_favorite_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/extensions/favorite_folder_view_pb_extensions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/widgets/page_item_more_action_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritePageItemMoreActionButton extends StatelessWidget {
  const FavoritePageItemMoreActionButton({
    super.key,
    required this.view,
  });

  final FavoriteFolderViewPB view;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.menuAppHeader_moreButtonToolTip.tr(),
      child: PageItemMoreActionPopover(
        view: view.view,
        spaceType: FolderSpaceType.favorite,
        isExpanded: false,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onAction: (action, _) {
          switch (action) {
            case ViewMoreActionType.favorite:
            case ViewMoreActionType.unFavorite:
              context
                  .read<FolderFavoriteBloc>()
                  .add(FolderFavoriteEvent.toggleFavorite(view.id));
              PopoverContainer.maybeOf(context)?.closeAll();
              break;
            case ViewMoreActionType.rename:
              NavigatorTextFieldDialog(
                title: LocaleKeys.disclosureAction_rename.tr(),
                autoSelectAllText: true,
                value: view.view.name,
                maxLength: 256,
                onConfirm: (newValue, _) {
                  // can not use bloc here because it has been disposed.
                  ViewBackendService.updateView(
                    viewId: view.view.viewId,
                    name: newValue,
                  );
                },
              ).show(context);
              PopoverContainer.maybeOf(context)?.closeAll();
              break;

            case ViewMoreActionType.openInNewTab:
              getIt<TabsBloc>().openTab(view.view.viewPB);
              break;
            case ViewMoreActionType.delete:
            case ViewMoreActionType.duplicate:
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
        buildChild: (popover) => FlowyIconButton(
          width: 24,
          icon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
          onPressed: () {
            popover.show();
          },
        ),
      ),
    );
  }
}
