import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_side_pannel_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatSidePannel extends StatelessWidget {
  const ChatSidePannel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSidePannelBloc, ChatSidePannelState>(
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
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FlowyIconButton(
                      icon: const FlowySvg(FlowySvgs.show_menu_s),
                      onPressed: () {
                        context
                            .read<ChatSidePannelBloc>()
                            .add(const ChatSidePannelEvent.close());
                      },
                    ),
                  ),
                  const VSpace(6),
                  Expanded(child: child),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
