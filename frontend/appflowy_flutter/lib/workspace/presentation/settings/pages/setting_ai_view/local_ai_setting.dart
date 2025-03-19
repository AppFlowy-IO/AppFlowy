import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/local_ai_setting_panel.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocalAISetting extends StatelessWidget {
  const LocalAISetting({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LocalAIToggleBloc()..add(const LocalAIToggleEvent.started()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ExpandableNotifier(
          child: BlocListener<LocalAIToggleBloc, LocalAIToggleState>(
            listener: (context, state) {
              final controller =
                  ExpandableController.of(context, required: true)!;

              state.pageIndicator.when(
                error: (_) => controller.expanded = true,
                isEnabled: (enabled) => controller.expanded = enabled,
                loading: () => controller.expanded = true,
              );
            },
            child: ExpandablePanel(
              theme: const ExpandableThemeData(
                headerAlignment: ExpandablePanelHeaderAlignment.center,
                tapBodyToCollapse: false,
                hasIcon: false,
                tapBodyToExpand: false,
                tapHeaderToExpand: false,
              ),
              header: const LocalAISettingHeader(),
              collapsed: const SizedBox.shrink(),
              expanded: Column(
                children: [
                  const VSpace(12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: LocalAISettingPanel(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LocalAISettingHeader extends StatelessWidget {
  const LocalAISettingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIToggleBloc, LocalAIToggleState>(
      builder: (context, state) {
        return state.pageIndicator.when(
          error: (error) => SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          isEnabled: (isEnabled) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FlowyText(
                      LocaleKeys.settings_aiPage_keys_localAIToggleTitle.tr(),
                    ),
                    const Spacer(),
                    Toggle(
                      value: isEnabled,
                      onChanged: (_) {
                        if (isEnabled) {
                          showConfirmDialog(
                            context: context,
                            title: LocaleKeys
                                .settings_aiPage_keys_disableLocalAITitle
                                .tr(),
                            description: LocaleKeys
                                .settings_aiPage_keys_disableLocalAIDescription
                                .tr(),
                            confirmLabel: LocaleKeys.button_confirm.tr(),
                            onConfirm: () => context
                                .read<LocalAIToggleBloc>()
                                .add(const LocalAIToggleEvent.toggle()),
                          );
                        } else {
                          context
                              .read<LocalAIToggleBloc>()
                              .add(const LocalAIToggleEvent.toggle());
                        }
                      },
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
            );
          },
        );
      },
    );
  }
}
