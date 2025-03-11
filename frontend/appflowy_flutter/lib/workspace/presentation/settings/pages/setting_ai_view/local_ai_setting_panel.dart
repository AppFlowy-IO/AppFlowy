import 'package:appflowy/workspace/application/settings/ai/local_ai_chat_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_chat_toggle_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/ollma_setting.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plugin_state.dart';

class LocalAISettingPanel extends StatelessWidget {
  const LocalAISettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LocalAISettingPanelBloc()),
        BlocProvider(
          create: (context) => LocalAIChatToggleBloc()
            ..add(const LocalAIChatToggleEvent.started()),
        ),
      ],
      child: ExpandableNotifier(
        initialExpanded: true,
        child: ExpandablePanel(
          theme: const ExpandableThemeData(
            headerAlignment: ExpandablePanelHeaderAlignment.center,
            tapBodyToCollapse: false,
            hasIcon: false,
            tapBodyToExpand: false,
            tapHeaderToExpand: false,
          ),
          header: const SizedBox.shrink(),
          collapsed: const SizedBox.shrink(),
          expanded: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<LocalAISettingPanelBloc, LocalAISettingPanelState>(
                  builder: (context, state) {
                    // If the progress indicator is startLocalAIApp, then don't show the LLM model.
                    if (state.progressIndicator ==
                        const LocalAIProgress.downloadLocalAIApp()) {
                      return const SizedBox.shrink();
                    } else {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          OllamaSettingPage(),
                          VSpace(6),
                          _LocalAIStateWidget(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalAIStateWidget extends StatelessWidget {
  const _LocalAIStateWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAISettingPanelBloc, LocalAISettingPanelState>(
      builder: (context, state) {
        return const PluginStateIndicator();
      },
    );
  }
}
