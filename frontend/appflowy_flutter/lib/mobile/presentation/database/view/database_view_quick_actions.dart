import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_transition_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'edit_database_view_screen.dart';

/// [MobileDatabaseViewQuickActions] is gives users to quickly edit a database
/// view from the [MobileDatabaseViewList]
class MobileDatabaseViewQuickActions extends StatelessWidget {
  const MobileDatabaseViewQuickActions({
    super.key,
    required this.view,
    required this.databaseController,
  });

  final ViewPB view;
  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    final isInline = view.childViews.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(context, _Action.edit, () async {
          final bloc = context.read<ViewBloc>();
          await showTransitionMobileBottomSheet(
            context,
            showHeader: true,
            showDoneButton: true,
            title: LocaleKeys.grid_settings_editView.tr(),
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: MobileEditDatabaseViewScreen(
                databaseController: databaseController,
              ),
            ),
          );
          if (context.mounted) {
            context.pop();
          }
        }),
        const MobileQuickActionDivider(),
        _actionButton(
          context,
          _Action.changeIcon,
          () {
            showMobileBottomSheet(
              context,
              showDragHandle: true,
              showDivider: false,
              showHeader: true,
              title: LocaleKeys.titleBar_pageIcon.tr(),
              backgroundColor: AFThemeExtension.of(context).background,
              enableDraggableScrollable: true,
              minChildSize: 0.6,
              initialChildSize: 0.61,
              scrollableWidgetBuilder: (_, controller) {
                return Expanded(
                  child: FlowyIconEmojiPicker(
                    tabs: const [PickerTabType.icon],
                    enableBackgroundColorSelection: false,
                    onSelectedEmoji: (r) {
                      ViewBackendService.updateViewIcon(
                        viewId: view.id,
                        viewIcon: r.data,
                      );
                      Navigator.pop(context);
                    },
                  ),
                );
              },
              builder: (_) => const SizedBox.shrink(),
            ).then((_) => Navigator.pop(context));
          },
          !isInline,
        ),
        const MobileQuickActionDivider(),
        _actionButton(
          context,
          _Action.duplicate,
          () {
            context.read<ViewBloc>().add(const ViewEvent.duplicate());
            context.pop();
          },
          !isInline,
        ),
        const MobileQuickActionDivider(),
        _actionButton(
          context,
          _Action.delete,
          () {
            context.read<ViewBloc>().add(const ViewEvent.delete());
            context.pop();
          },
          !isInline,
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    _Action action,
    VoidCallback onTap, [
    bool enable = true,
  ]) {
    return MobileQuickActionButton(
      icon: action.icon,
      text: action.label,
      textColor: action.color(context),
      iconColor: action.color(context),
      onTap: onTap,
      enable: enable,
    );
  }
}

enum _Action {
  edit,
  changeIcon,
  delete,
  duplicate;

  String get label {
    return switch (this) {
      edit => LocaleKeys.grid_settings_editView.tr(),
      duplicate => LocaleKeys.button_duplicate.tr(),
      delete => LocaleKeys.button_delete.tr(),
      changeIcon => LocaleKeys.disclosureAction_changeIcon.tr(),
    };
  }

  FlowySvgData get icon {
    return switch (this) {
      edit => FlowySvgs.view_item_rename_s,
      duplicate => FlowySvgs.duplicate_s,
      delete => FlowySvgs.trash_s,
      changeIcon => FlowySvgs.change_icon_s,
    };
  }

  Color? color(BuildContext context) {
    return switch (this) {
      delete => Theme.of(context).colorScheme.error,
      _ => null,
    };
  }
}
