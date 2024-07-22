import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/footer/sidebar_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SidebarToast(),
        Row(
          children: [
            Expanded(child: SidebarTrashButton()),
            // Enable it when the widget button is ready
            // SizedBox(
            //   height: 16,
            //   child: VerticalDivider(width: 1, color: Color(0x141F2329)),
            // ),
            // Expanded(child: SidebarWidgetButton()),
          ],
        ),
      ],
    );
  }
}

class SidebarTrashButton extends StatelessWidget {
  const SidebarTrashButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.workspaceSectionHeight,
      child: ValueListenableBuilder(
        valueListenable: getIt<MenuSharedState>().notifier,
        builder: (context, value, child) {
          return FlowyButton(
            leftIcon: const FlowySvg(FlowySvgs.sidebar_footer_trash_m),
            leftIconSize: const Size.square(24.0),
            iconPadding: 8.0,
            margin: const EdgeInsets.all(4.0),
            text: FlowyText.regular(
              LocaleKeys.trash_text.tr(),
              lineHeight: 1.15,
            ),
            onTap: () {
              getIt<MenuSharedState>().latestOpenView = null;
              getIt<TabsBloc>().add(
                TabsEvent.openPlugin(
                  plugin: makePlugin(pluginType: PluginType.trash),
                ),
              );
            },
          );
        },
      ),
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
