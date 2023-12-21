import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'edit_database_view_screen.dart';

/// [MobileDatabaseViewQuickActions] is gives users to quickly edit a database
/// view from the [MobileDatabaseViewList]
class MobileDatabaseViewQuickActions extends StatefulWidget {
  const MobileDatabaseViewQuickActions({
    super.key,
    required this.view,
    required this.databaseController,
  });

  final ViewPB view;
  final DatabaseController databaseController;

  @override
  State<MobileDatabaseViewQuickActions> createState() =>
      _MobileDatabaseViewQuickActionsState();
}

class _MobileDatabaseViewQuickActionsState
    extends State<MobileDatabaseViewQuickActions> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return isEditing
        ? MobileEditDatabaseViewScreen(
            databaseController: widget.databaseController,
          )
        : Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 38),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(context, _Action.edit),
                _divider(),
                _actionButton(context, _Action.duplicate),
                _divider(),
                _actionButton(context, _Action.delete),
                _divider(),
              ],
            ),
          );
  }

  Widget _actionButton(BuildContext context, _Action action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MobileQuickActionButton(
        icon: action.icon,
        text: action.label,
        color: action.color(context),
        onTap: () {
          if (action == _Action.edit) {
            setState(() => isEditing = true);
          }
        },
      ),
    );
  }

  Widget _divider() => const Divider(height: 9);
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
