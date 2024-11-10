import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_side_panel_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatSidePanel extends StatelessWidget {
  const ChatSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSidePanelBloc, ChatSidePanelState>(
      builder: (context, state) {
        return state.indicator.when(
          loading: () {
            return const CircularProgressIndicator.adaptive();
          },
          ready: (view) {
            final plugin = view.plugin();
            plugin.init();

            final pluginContext = PluginContext();
            final child = plugin.widgetBuilder
                .buildWidget(context: pluginContext, shrinkWrap: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlowyIconButton(
                    icon: const FlowySvg(FlowySvgs.show_menu_s),
                    onPressed: () {
                      context
                          .read<ChatSidePanelBloc>()
                          .add(const ChatSidePanelEvent.close());
                    },
                  ),
                ),
                const VSpace(6),
                Expanded(child: child),
              ],
            );
          },
        );
      },
    );
  }
}
