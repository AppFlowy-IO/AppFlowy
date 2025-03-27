import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/local_ai_setting_panel.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocalAISetting extends StatefulWidget {
  const LocalAISetting({super.key});

  @override
  State<LocalAISetting> createState() => _LocalAISettingState();
}

class _LocalAISettingState extends State<LocalAISetting> {
  final expandableController = ExpandableController(initialExpanded: false);

  @override
  void dispose() {
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocalAIToggleBloc(),
      child: BlocConsumer<LocalAIToggleBloc, LocalAiToggleState>(
        listener: (context, state) {
          final newIsExpanded = switch (state) {
            final ReadyLocalAiToggleState readyLocalAiToggleState =>
              readyLocalAiToggleState.isEnabled,
            _ => false,
          };
          expandableController.value = newIsExpanded;
        },
        builder: (context, state) {
          return ExpandablePanel(
            controller: expandableController,
            theme: ExpandableThemeData(
              tapBodyToCollapse: false,
              hasIcon: false,
              tapBodyToExpand: false,
              tapHeaderToExpand: false,
            ),
            header: LocalAiSettingHeader(
              isEnabled: state is ReadyLocalAiToggleState && state.isEnabled,
              isToggleable: state is ReadyLocalAiToggleState,
            ),
            collapsed: const SizedBox.shrink(),
            expanded: Container(
              margin: EdgeInsets.only(top: 12),
              child: LocalAISettingPanel(),
            ),
          );
        },
      ),
    );
  }
}

class LocalAiSettingHeader extends StatelessWidget {
  const LocalAiSettingHeader({
    super.key,
    required this.isEnabled,
    required this.isToggleable,
  });

  final bool isEnabled;
  final bool isToggleable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowyText.medium(
                LocaleKeys.settings_aiPage_keys_localAIToggleTitle.tr(),
              ),
              const VSpace(4),
              FlowyText(
                LocaleKeys.settings_aiPage_keys_localAIToggleSubTitle.tr(),
                maxLines: 3,
                fontSize: 12,
              ),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: !isToggleable,
          child: Opacity(
            opacity: isToggleable ? 1 : 0.5,
            child: Toggle(
              value: isEnabled,
              onChanged: (_) => _onToggleChanged(context),
            ),
          ),
        ),
      ],
    );
  }

  void _onToggleChanged(BuildContext context) {
    if (isEnabled) {
      showConfirmDialog(
        context: context,
        title: LocaleKeys.settings_aiPage_keys_disableLocalAITitle.tr(),
        description:
            LocaleKeys.settings_aiPage_keys_disableLocalAIDescription.tr(),
        confirmLabel: LocaleKeys.button_confirm.tr(),
        onConfirm: () {
          context
              .read<LocalAIToggleBloc>()
              .add(const LocalAIToggleEvent.toggle());
        },
      );
    } else {
      context.read<LocalAIToggleBloc>().add(const LocalAIToggleEvent.toggle());
    }
  }
}
