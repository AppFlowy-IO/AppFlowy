import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum MobileBlockActionType {
  delete,
  duplicate,
  insertAbove,
  insertBelow,
  color;

  static List<MobileBlockActionType> get standard => [
        MobileBlockActionType.delete,
        MobileBlockActionType.duplicate,
        MobileBlockActionType.insertAbove,
        MobileBlockActionType.insertBelow,
      ];

  static MobileBlockActionType fromActionString(String actionString) {
    return MobileBlockActionType.values.firstWhere(
      (e) => e.actionString == actionString,
      orElse: () => throw Exception('Unknown action string: $actionString'),
    );
  }

  String get actionString => toString();

  FlowySvgData get icon {
    return switch (this) {
      MobileBlockActionType.delete => FlowySvgs.m_delete_m,
      MobileBlockActionType.duplicate => FlowySvgs.m_duplicate_m,
      MobileBlockActionType.insertAbove => FlowySvgs.arrow_up_s,
      MobileBlockActionType.insertBelow => FlowySvgs.arrow_down_s,
      MobileBlockActionType.color => FlowySvgs.m_color_m,
    };
  }

  String get i18n {
    return switch (this) {
      MobileBlockActionType.delete => LocaleKeys.button_delete.tr(),
      MobileBlockActionType.duplicate => LocaleKeys.button_duplicate.tr(),
      MobileBlockActionType.insertAbove => LocaleKeys.button_insertAbove.tr(),
      MobileBlockActionType.insertBelow => LocaleKeys.button_insertBelow.tr(),
      MobileBlockActionType.color =>
        LocaleKeys.document_plugins_optionAction_color.tr(),
    };
  }
}

class MobileBlockSettingsScreen extends StatelessWidget {
  static const routeName = '/block_settings';

  // the action string comes from the enum MobileBlockActionType
  // example: MobileBlockActionType.delete.actionString, MobileBlockActionType.duplicate.actionString, etc.
  static const supportedActions = 'actions';

  const MobileBlockSettingsScreen({
    super.key,
    required this.actions,
  });

  final List<MobileBlockActionType> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: FlowyText.semibold(
          LocaleKeys.titleBar_actions.tr(),
          fontSize: 14.0,
        ),
        leading: const AppBarBackButton(),
      ),
      body: SafeArea(
        child: ListView.separated(
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return FlowyButton(
              text: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 18.0,
                ),
                child: FlowyText(action.i18n),
              ),
              leftIcon: FlowySvg(action.icon),
              leftIconSize: const Size.square(24),
              onTap: () {},
            );
          },
          separatorBuilder: (context, index) => const Divider(
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
