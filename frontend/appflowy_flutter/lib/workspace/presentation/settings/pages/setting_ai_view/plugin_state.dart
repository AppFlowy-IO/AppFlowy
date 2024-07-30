import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/download_offline_ai_app_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/plugin_state_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
          return state.action.when(
            init: () => const _InitPlugin(),
            ready: () => const _LocalAIReadyToUse(),
            restartPlugin: () => const _ReloadButton(),
            loadingPlugin: () => const _InitPlugin(),
            startAIOfflineApp: () => OpenOrDownloadOfflineAIApp(
              onRetry: () {
                context
                    .read<PluginStateBloc>()
                    .add(const PluginStateEvent.started());
              },
            ),
          );
        },
      ),
    );
  }
}

class _InitPlugin extends StatelessWidget {
  const _InitPlugin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: CircularProgressIndicator.adaptive(),
    );
  }
}

class _ReloadButton extends StatelessWidget {
  const _ReloadButton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlowySvg(
          FlowySvgs.download_warn_s,
          color: Color(0xFFC62828),
        ),
        const HSpace(6),
        FlowyText(LocaleKeys.settings_aiPage_keys_failToLoadLocalAI.tr()),
        const Spacer(),
        SizedBox(
          height: 30,
          child: FlowyButton(
            useIntrinsicWidth: true,
            text:
                FlowyText(LocaleKeys.settings_aiPage_keys_restartLocalAI.tr()),
            onTap: () {
              context.read<PluginStateBloc>().add(
                    const PluginStateEvent.restartLocalAI(),
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _LocalAIReadyToUse extends StatelessWidget {
  const _LocalAIReadyToUse();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFEDF7ED),
        borderRadius: BorderRadius.all(
          Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const HSpace(8),
            const FlowySvg(
              FlowySvgs.download_success_s,
              color: Color(0xFF2E7D32),
            ),
            const HSpace(6),
            FlowyText(
              LocaleKeys.settings_aiPage_keys_localAILoaded.tr(),
              fontSize: 11,
              color: const Color(0xFF1E4620),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FlowyButton(
                useIntrinsicWidth: true,
                text: FlowyText(
                  LocaleKeys.settings_aiPage_keys_openModelDirectory.tr(),
                  fontSize: 11,
                  color: const Color(0xFF1E4620),
                ),
                onTap: () {
                  context.read<PluginStateBloc>().add(
                        const PluginStateEvent.openModelDirectory(),
                      );
                },
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                FlowyText(
                  LocaleKeys.settings_aiPage_keys_offlineAINotReady.tr(),
                  lineHeight: 1.5,
                  maxLines: 6,
                ),
                const VSpace(12),
                Row(
                  children: [
                    SizedBox(
                      height: 30,
                      child: FlowyButton(
                        useIntrinsicWidth: true,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        text: FlowyText(
                          LocaleKeys.settings_aiPage_keys_retryOfflineAI.tr(),
                        ),
                        onTap: () => onRetry(),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: FlowyButton(
                        useIntrinsicWidth: true,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        text: FlowyText(
                          LocaleKeys.settings_aiPage_keys_downloadOfflineAI
                              .tr(),
                        ),
                        onTap: () {
                          context.read<DownloadOfflineAIBloc>().add(
                                const DownloadOfflineAIEvent.started(),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
