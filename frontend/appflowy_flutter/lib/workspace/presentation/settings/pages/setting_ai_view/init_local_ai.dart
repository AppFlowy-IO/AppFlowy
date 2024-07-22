import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_chat_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InitLocalAIIndicator extends StatelessWidget {
  const InitLocalAIIndicator({super.key});

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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: BlocBuilder<LocalAIChatSettingBloc, LocalAIChatSettingState>(
          builder: (context, state) {
            switch (state.runningState) {
              case RunningStatePB.Connecting:
              case RunningStatePB.Connected:
                return Row(
                  children: [
                    const HSpace(8),
                    FlowyText(
                      LocaleKeys.settings_aiPage_keys_localAILoading.tr(),
                      fontSize: 11,
                      color: const Color(0xFF1E4620),
                    ),
                  ],
                );
              case RunningStatePB.Running:
                return Row(
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
                  ],
                );
              case RunningStatePB.Stopped:
                return Row(
                  children: [
                    const HSpace(8),
                    FlowyText(
                      LocaleKeys.settings_aiPage_keys_localAIStopped.tr(),
                      fontSize: 11,
                      color: const Color(0xFFC62828),
                    ),
                  ],
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
