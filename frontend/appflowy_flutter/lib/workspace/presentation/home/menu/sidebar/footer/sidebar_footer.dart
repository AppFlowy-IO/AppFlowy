import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:flutter/material.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SidebarTrashButton()),
        SizedBox(
          height: 16,
          child: VerticalDivider(width: 1, color: Color(0x141F2329)),
        ),
        Expanded(child: SidebarWidgetButton()),
      ],
    );
  }
}

class SidebarTrashButton extends StatelessWidget {
  const SidebarTrashButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (context, value, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              getIt<MenuSharedState>().latestOpenView = null;
              getIt<TabsBloc>().add(
                TabsEvent.openPlugin(
                  plugin: makePlugin(pluginType: PluginType.trash),
                ),
              );
            },
            child: const FlowySvg(FlowySvgs.sidebar_footer_trash_s),
          ),
        );
      },
    );
  }
}

class SidebarWidgetButton extends StatelessWidget {
  const SidebarWidgetButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: const FlowySvg(FlowySvgs.sidebar_footer_widget_s),
      ),
    );
  }
}
