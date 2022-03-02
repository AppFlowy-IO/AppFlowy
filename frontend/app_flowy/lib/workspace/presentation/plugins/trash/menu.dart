import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/startup/tasks/load_plugin.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class MenuTrash extends StatelessWidget {
  const MenuTrash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: InkWell(
        onTap: () {
          Provider.of<MenuSharedState>(context, listen: false).selectedView.value = null;
          getIt<HomeStackManager>().setPlugin(makePlugin(pluginType: DefaultPlugin.trash.type()));
        },
        child: _render(context),
      ),
    );
  }

  Widget _render(BuildContext context) {
    return Row(children: [
      // SizedBox(width: 16, height: 16, child: svg("home/trash", color: Theme.of(context).iconTheme.color!)),
      // ChangeNotifierProvider.value(
      //   value: Provider.of<AppearanceSettingModel>(context, listen: true),
      //   child: Selector<AppearanceSettingModel, AppTheme>(
      //     selector: (ctx, notifier) => notifier.theme,
      //     builder: (ctx, theme, child) =>
      //         SizedBox(width: 16, height: 16, child: svg("home/trash", color: theme.iconColor)),
      //   ),
      // ),
      const HSpace(6),
      BlocSelector<AppearanceSettingsCubit, AppearanceSettingsState, Locale>(
        selector: (state) => state.locale,
        builder: (context, state) => FlowyText.medium(LocaleKeys.trash_text.tr(), fontSize: 12),
      ),
    ]);
  }
}
