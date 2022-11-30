import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class MenuTrash extends StatelessWidget {
  const MenuTrash({Key? key}) : super(key: key);

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
                getIt<HomeStackManager>()
                    .setPlugin(makePlugin(pluginType: PluginType.trash));
              },
              child: _render(context),
            ),
          ).padding(horizontal: Insets.l),
        ).padding(horizontal: 8);
      },
    );
  }

  Widget _render(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: svgWidget(
            "home/trash",
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const HSpace(6),
        FlowyText.medium(LocaleKeys.trash_text.tr()),
      ],
    );
  }
}