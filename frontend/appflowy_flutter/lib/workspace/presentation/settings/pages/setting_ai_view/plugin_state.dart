import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/plugin_state_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/init_local_ai.dart';
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
            unknown: () => const SizedBox.shrink(),
            readToRun: () => const _PrepareRunning(),
            initializingPlugin: () => const InitLocalAIIndicator(),
            running: (version) => _LocalAIRunning(version: version),
            restartPlugin: () => const _RestartPluginButton(),
            lackOfResource: (desc) => _LackOfResource(desc: desc),
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
    return Row(
      children: [
        Expanded(
          child: FlowyText(
            LocaleKeys.settings_aiPage_keys_localAIStart.tr(),
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

class _RestartPluginButton extends StatelessWidget {
  const _RestartPluginButton();

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

class _LocalAIRunning extends StatelessWidget {
  const _LocalAIRunning({required this.version});

  final String version;

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  const HSpace(8),
                  const FlowySvg(
                    FlowySvgs.download_success_s,
                    color: Color(0xFF2E7D32),
                  ),
                  const HSpace(6),
                  Flexible(
                    child: FlowyText(
                      LocaleKeys.settings_aiPage_keys_localAIRunning.tr(
                        args: [
                          version,
                        ],
                      ),
                      fontSize: 11,
                      color: const Color(0xFF1E4620),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LackOfResource extends StatelessWidget {
  const _LackOfResource({required this.desc});

  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowySvg(
          FlowySvgs.toast_warning_filled_s,
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
    );
  }
}
