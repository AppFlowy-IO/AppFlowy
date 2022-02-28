import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/home/navigation.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:provider/provider.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      color: theme.surface,
      height: HomeSizes.topBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const FlowyNavigation(),
          const HSpace(16),
          ChangeNotifierProvider.value(
            value: Provider.of<HomeStackNotifier>(context, listen: false),
            child: Consumer(
              builder: (BuildContext context, HomeStackNotifier notifier, Widget? child) {
                return notifier.plugin.display.rightBarItem ?? const SizedBox();
              },
            ),
          ) // _renderMoreButton(),
        ],
      )
          .padding(
            horizontal: HomeInsets.topBarTitlePadding,
          )
          .bottomBorder(color: Colors.grey.shade300),
    );
  }
}
