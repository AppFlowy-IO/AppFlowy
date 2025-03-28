import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/ai/download_offline_ai_app_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/plugin_state_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/init_local_ai.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PluginStateIndicator extends StatelessWidget {
  const PluginStateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PluginStateBloc()..add(const PluginStateEvent.started()),
      child: BlocBuilder<PluginStateBloc, PluginStateState>(
        builder: (context, state) {
          return Container(
            height: 32,
            alignment: AlignmentDirectional.centerStart,
            child: state.action.when(
              unknown: () => const SizedBox.shrink(),
              readToRun: () => const _PrepareRunning(),
              initializingPlugin: () => const InitLocalAIIndicator(),
              running: () => const _LocalAIRunning(),
              restartPlugin: () => const _RestartPluginButton(),
              lackOfResource: (desc) => _LackOfResource(desc: desc),
            ),
          );
        },
      ),
    );
  }
}

class _PrepareRunning extends StatelessWidget {
  const _PrepareRunning();

  @override
  Widget build(BuildContext context) {
    return FlowyText(
      LocaleKeys.settings_aiPage_keys_localAIStart.tr(),
      maxLines: 3,
    );
  }
}

class _RestartPluginButton extends StatelessWidget {
  const _RestartPluginButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).isLightMode
            ? const Color(0x80FFE7EE)
            : const Color(0x80591734),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            const FlowySvg(
              FlowySvgs.toast_warning_filled_s,
              color: Color(0xFFC62828),
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText(
                LocaleKeys.settings_aiPage_keys_failToLoadLocalAI.tr(),
              ),
            ),
            FlowyButton(
              useIntrinsicWidth: true,
              text: FlowyText(
                LocaleKeys.settings_aiPage_keys_restartLocalAI.tr(),
              ),
              onTap: () {
                context
                    .read<PluginStateBloc>()
                    .add(const PluginStateEvent.restartLocalAI());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalAIRunning extends StatelessWidget {
  const _LocalAIRunning();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFEDF7ED),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            const FlowySvg(
              FlowySvgs.download_success_s,
              color: Color(0xFF2E7D32),
            ),
            const HSpace(6),
            Flexible(
              child: FlowyText(
                LocaleKeys.settings_aiPage_keys_localAIRunning.tr(),
                color: const Color(0xFF1E4620),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenOrDownloadOfflineAIApp extends StatelessWidget {
  const OpenOrDownloadOfflineAIApp({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloadOfflineAIBloc(),
      child: BlocBuilder<DownloadOfflineAIBloc, DownloadOfflineAIState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 3,
                textAlign: TextAlign.left,
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          "${LocaleKeys.settings_aiPage_keys_offlineAIInstruction1.tr()} ",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(height: 1.5),
                    ),
                    TextSpan(
                      text:
                          " ${LocaleKeys.settings_aiPage_keys_offlineAIInstruction2.tr()} ",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: FontSizes.s14,
                            color: Theme.of(context).colorScheme.primary,
                            height: 1.5,
                          ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => afLaunchUrlString(
                              "https://docs.appflowy.io/docs/appflowy/product/appflowy-ai-offline",
                            ),
                    ),
                    TextSpan(
                      text:
                          " ${LocaleKeys.settings_aiPage_keys_offlineAIInstruction3.tr()} ",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(height: 1.5),
                    ),
                    TextSpan(
                      text:
                          "${LocaleKeys.settings_aiPage_keys_offlineAIDownload1.tr()} ",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(height: 1.5),
                    ),
                    TextSpan(
                      text:
                          " ${LocaleKeys.settings_aiPage_keys_offlineAIDownload2.tr()} ",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: FontSizes.s14,
                            color: Theme.of(context).colorScheme.primary,
                            height: 1.5,
                          ),
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () => context.read<DownloadOfflineAIBloc>().add(
                                  const DownloadOfflineAIEvent.started(),
                                ),
                    ),
                    TextSpan(
                      text:
                          " ${LocaleKeys.settings_aiPage_keys_offlineAIDownload3.tr()} ",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LackOfResource extends StatelessWidget {
  const _LackOfResource({required this.desc});

  final String desc;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).isLightMode
            ? const Color(0x80FFE7EE)
            : const Color(0x80591734),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.toast_error_filled_s,
              size: const Size.square(20.0),
              blendMode: null,
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText(
                desc,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
