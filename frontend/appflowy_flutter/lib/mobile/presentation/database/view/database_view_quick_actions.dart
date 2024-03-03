import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_transition_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
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
        _divider(),
        _actionButton(
          context,
          _Action.duplicate,
          () {
            context.read<ViewBloc>().add(const ViewEvent.duplicate());
            context.pop();
          },
          !isInline,
        ),
        _divider(),
        _actionButton(
          context,
          _Action.delete,
          () {
            context.read<ViewBloc>().add(const ViewEvent.delete());
            context.pop();
          },
          !isInline,
        ),
        _divider(),
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

  Widget _divider() => const Divider(height: 8.5, thickness: 0.5);
}

enum _Action {
  edit,
  duplicate,
  delete;

  String get label {
    return switch (this) {
      edit => LocaleKeys.grid_settings_editView.tr(),
      duplicate => LocaleKeys.button_duplicate.tr(),
      delete => LocaleKeys.button_delete.tr(),
    };
  }

  FlowySvgData get icon {
    return switch (this) {
      edit => FlowySvgs.edit_s,
      duplicate => FlowySvgs.copy_s,
      delete => FlowySvgs.delete_s,
    };
  }

  Color? color(BuildContext context) {
    return switch (this) {
      delete => Theme.of(context).colorScheme.error,
      _ => null,
    };
  }
}
