import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// [MobileDatabaseViewQuickActions] is gives users to quickly edit a database
/// view from the [MobileDatabaseViewList]
class MobileDatabaseViewQuickActions extends StatelessWidget {
  const MobileDatabaseViewQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(_Action.edit),
        _divider(),
        _actionButton(_Action.duplicate),
        _divider(),
        _actionButton(_Action.delete),
        _divider(),
      ],
    );
  }

  Widget _actionButton(_Action action) {
    return MobileQuickActionButton(
      icon: action.icon,
      text: action.label,
      onTap: () {},
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
      edit => FlowySvgs.grid_s,
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
