import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/app/app_widget.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/styled_icon_button.dart';
import 'package:flowy_infra_ui/style_widget/styled_hover.dart';

class ViewWidget extends StatelessWidget {
  final View view;
  const ViewWidget({Key? key, required this.view}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openView(context),
      child: StyledHover(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        builder: (context, onHover) => _render(context, onHover),
      ),
    );
  }

  Widget _render(BuildContext context, bool onHover) {
    const double width = 20;
    List<Widget> children = [
      Image(
          fit: BoxFit.cover,
          width: width,
          height: width,
          image: assetImageForViewType(view.viewType)),
      const HSpace(6),
      Text(
        view.name,
        textAlign: TextAlign.start,
        style: const TextStyle(fontSize: 15),
      ),
    ];

    if (onHover) {
      children.add(const Spacer());

      children.add(Align(
        alignment: Alignment.center,
        child: StyledMore(
          width: width,
          onPressed: () {},
        ),
      ));
    }

    final padding = EdgeInsets.only(
      left: AppWidgetSize.expandedPadding,
      top: 5,
      bottom: 5,
      right: 5,
    );

    return Padding(
      padding: padding,
      child: Row(children: children),
    );
  }

  Function() _openView(BuildContext context) {
    return () {
      final stackView = stackViewFromView(view);
      getIt<HomePageStack>().setStackView(stackView);
    };
  }
}
