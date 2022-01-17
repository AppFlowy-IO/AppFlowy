import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/home/navigation.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/view_create.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:provider/provider.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
                return notifier.stackContext.rightBarItem ?? const SizedBox();
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

class HomeTitle extends StatelessWidget {
  final String title;
  final ViewType type;

  const HomeTitle({
    Key? key,
    required this.title,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        children: [
          Image(fit: BoxFit.scaleDown, width: 15, height: 15, image: assetImageForViewType(type)),
          const HSpace(6),
          FlowyText(title, fontSize: 16),
        ],
      ),
    );
  }
}
