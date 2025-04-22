import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ollama_setting.dart';
import 'plugin_status_indicator.dart';

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
      create: (context) => LocalAiPluginBloc(),
      child: BlocConsumer<LocalAiPluginBloc, LocalAiPluginState>(
        listener: (context, state) {
          expandableController.value = state.isEnabled;
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
              isEnabled: state.isEnabled,
            ),
            collapsed: const SizedBox.shrink(),
            expanded: Padding(
              padding: EdgeInsets.only(top: 12),
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
  });

  final bool isEnabled;

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
        Toggle(
          value: isEnabled,
          onChanged: (_) => _onToggleChanged(context),
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
              .read<LocalAiPluginBloc>()
              .add(const LocalAiPluginEvent.toggle());
        },
      );
    } else {
      context.read<LocalAiPluginBloc>().add(const LocalAiPluginEvent.toggle());
    }
  }
}

class LocalAISettingPanel extends StatelessWidget {
  const LocalAISettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAiPluginBloc, LocalAiPluginState>(
      builder: (context, state) {
        if (state is! ReadyLocalAiPluginState) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LocalAIStatusIndicator(),
            const VSpace(10),
            OllamaSettingPage(),
          ],
        );
      },
    );
  }
}
