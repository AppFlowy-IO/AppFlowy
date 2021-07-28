import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
// import 'package:flowy_infra_ui/style_widget/styled_navigation_list.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

class HomeTopBar extends StatelessWidget {
  final HomeStackView view;
  const HomeTopBar({Key? key, required this.view}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.topBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeTitle(title: view.title, type: view.type),
          const Spacer(),
          _renderShareButton(),
          _renderMoreButton(),
        ],
      )
          .padding(horizontal: HomeInsets.topBarTitlePadding)
          .bottomBorder(color: Colors.grey.shade300),
    );
  }

  Widget _renderShareButton() {
    return RoundedTextButton(
      title: 'Share',
      height: 30,
      width: 60,
      fontSize: 12,
      borderRadius: BorderRadius.circular(6),
      color: Colors.lightBlue,
      press: () {
        debugPrint('share page');
      },
    );
  }

  Widget _renderMoreButton() {
    return FlowyMoreButton(
      width: 24,
      onPressed: () {
        debugPrint('show more');
      },
    );
  }

  Widget _renderNavigationList() {
    return Container();
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
          Image(
              fit: BoxFit.scaleDown,
              width: 15,
              height: 15,
              image: assetImageForViewType(type)),
          const HSpace(6),
          FlowyText(title, fontSize: 16),
        ],
      ),
    );
  }
}
