import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class SidebarTrashButton extends StatelessWidget {
  const SidebarTrashButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (context, value, child) {
        return FlowyHover(
          style: HoverStyle(
            hoverColor: AFThemeExtension.of(context).greySelect,
          ),
          isSelected: () => getIt<MenuSharedState>().latestOpenView == null,
          child: SizedBox(
            height: 26,
            child: InkWell(
              onTap: () {
                getIt<MenuSharedState>().latestOpenView = null;
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: makePlugin(pluginType: PluginType.trash),
                  ),
                );
              },
              child: _buildTextButton(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return Row(
      children: [
        const HSpace(6),
        const FlowySvg(
          FlowySvgs.trash_m,
          size: Size(16, 16),
        ),
        const HSpace(6),
        FlowyText.medium(
          LocaleKeys.trash_text.tr(),
        ),
      ],
    );
  }
}
