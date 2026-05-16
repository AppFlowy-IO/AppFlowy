import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
    final theme = AppFlowyTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    LocaleKeys.settings_aiPage_keys_localAIToggleTitle.tr(),
                    style: theme.textStyle.body.enhanced(
                      color: theme.textColorScheme.primary,
                    ),
                  ),
                  HSpace(theme.spacing.s),
                  FlowyTooltip(
                    message: LocaleKeys.workspace_learnMore.tr(),
                    child: AFGhostButton.normal(
                      padding: EdgeInsets.zero,
                      builder: (context, isHovering, disabled) {
                        return FlowySvg(
                          FlowySvgs.ai_explain_m,
                          size: Size.square(20),
                        );
                      },
                      onTap: () {
                        afLaunchUrlString(
                          'https://appflowy.com/guide/appflowy-local-ai-ollama',
                        );
                      },
                    ),
                  ),
                ],
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
          onChanged: (value) {
            _onToggleChanged(value, context);
          },
        ),
      ],
    );
  }

  void _onToggleChanged(bool value, BuildContext context) {
    if (value) {
      context.read<LocalAiPluginBloc>().add(const LocalAiPluginEvent.toggle());
    } else {
      showConfirmDialog(
        context: context,
        title: LocaleKeys.settings_aiPage_keys_disableLocalAITitle.tr(),
        description:
            LocaleKeys.settings_aiPage_keys_disableLocalAIDescription.tr(),
        confirmLabel: LocaleKeys.button_confirm.tr(),
        onConfirm: (_) {
          context
              .read<LocalAiPluginBloc>()
              .add(const LocalAiPluginEvent.toggle());
        },
      );
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
