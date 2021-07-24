import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class ViewWidget extends StatelessWidget {
  final View view;
  final Widget icon;
  const ViewWidget({Key? key, required this.view, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: _openView(context), child: buildContent());
  }

  Row buildContent() {
    return Row(
      children: [
        icon,
        const SizedBox(
          width: 4,
        ),
        Text(
          view.name,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 15),
        )
      ],
    );
  }

  Function() _openView(BuildContext context) {
    return () {
      final stackView = stackViewFromView(view);
      getIt<HomePageStack>().setStackView(stackView);
    };
  }
}
