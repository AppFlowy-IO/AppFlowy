import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_setting_panel_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/ollama_setting.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plugin_state.dart';

class LocalAISettingPanel extends StatelessWidget {
  const LocalAISettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocalAISettingPanelBloc(),
      child: BlocBuilder<LocalAISettingPanelBloc, LocalAISettingPanelState>(
        builder: (context, state) {
          final isReady = state.runningState == RunningStatePB.Running;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace(10),
              if (isReady)
                OllamaSettingPage()
              else ...[
                PluginStateIndicator(),
                VSpace(10),
                _InstallOllamaInstruction(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InstallOllamaInstruction extends StatelessWidget {
  const _InstallOllamaInstruction();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontSize: 12, height: 1.5);
    return RichText(
      maxLines: 3,
      textAlign: TextAlign.left,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: LocaleKeys.settings_aiPage_keys_localAISetupInstruction1.tr(),
            style: textStyle?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          TextSpan(
            text:
                " ${LocaleKeys.settings_aiPage_keys_localAISetupInstruction2.tr()} ",
            style: textStyle?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => afLaunchUrlString(
                    "https://appflowy.com/guide/appflowy-local-ai-ollama",
                  ),
          ),
          TextSpan(
            text: LocaleKeys.settings_aiPage_keys_localAISetupInstruction3.tr(),
            style: textStyle?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
