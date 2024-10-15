import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/base/mobile_view_page_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MobileViewBottomSheetBodyAction {
  undo,
  redo,
  rename,
  duplicate,
  delete,
  addToFavorites,
  removeFromFavorites,
  helpCenter,
  publish,
  unpublish,
  copyPublishLink,
  visitSite,
  copyShareLink,
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
        MobileQuickActionButton(
          text: LocaleKeys.button_rename.tr(),
          icon: FlowySvgs.view_item_rename_s,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.rename,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: isFavorite
              ? LocaleKeys.button_removeFromFavorites.tr()
              : LocaleKeys.button_addToFavorites.tr(),
          icon: isFavorite ? FlowySvgs.unfavorite_s : FlowySvgs.favorite_s,
          onTap: () => onAction(
            isFavorite
                ? MobileViewBottomSheetBodyAction.removeFromFavorites
                : MobileViewBottomSheetBodyAction.addToFavorites,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: LocaleKeys.button_duplicate.tr(),
          icon: FlowySvgs.duplicate_s,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.duplicate,
          ),
        ),
        // copy link
        _divider(),
        MobileQuickActionButton(
          text: 'Copy share link',
          icon: FlowySvgs.m_toolbar_link_m,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.copyShareLink,
          ),
        ),
        _divider(),
        ..._buildPublishActions(context),
        _divider(),
        MobileQuickActionButton(
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          icon: FlowySvgs.trash_s,
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.delete,
          ),
        ),
        _divider(),
      ],
    );
  }

  List<Widget> _buildPublishActions(BuildContext context) {
    final userProfile = context.read<MobileViewPageBloc>().state.userProfilePB;
    // the publish feature is only available for AppFlowy Cloud
    if (userProfile == null ||
        userProfile.authenticator != AuthenticatorPB.AppFlowyCloud) {
      return [];
    }

    final isPublished = context.watch<ShareBloc>().state.isPublished;
    if (isPublished) {
      return [
        MobileQuickActionButton(
          text: LocaleKeys.shareAction_visitSite.tr(),
          icon: FlowySvgs.share_s,
          iconSize: const Size.square(21),
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.visitSite,
          ),
        ),
        _divider(),
        MobileQuickActionButton(
          text: LocaleKeys.shareAction_unPublish.tr(),
          icon: FlowySvgs.m_unpublish_s,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.unpublish,
          ),
        ),
      ];
    } else {
      return [
        MobileQuickActionButton(
          text: LocaleKeys.shareAction_publish.tr(),
          icon: FlowySvgs.m_publish_s,
          onTap: () => onAction(
            MobileViewBottomSheetBodyAction.publish,
          ),
        ),
      ];
    }
  }

  Widget _divider() => const Divider(
        height: 8.5,
        thickness: 0.5,
      );
}
