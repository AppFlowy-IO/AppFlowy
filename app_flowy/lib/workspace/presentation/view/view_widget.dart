import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class ViewWidget extends StatelessWidget {
  final View view;
  final Widget icon;
  const ViewWidget({Key? key, required this.view, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: _handleTapOnView(context),
        child: Container(
          height: 30,
          child: buildContent(),
        ));
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

  Function() _handleTapOnView(BuildContext context) {
    return () {
      // if (view.id.startsWith('doc')) {
      //   context.read<MenuBloc>().add(MenuEvent.openPage(DocPageContext(view)));
      //   return;
      // }

      // context.read<MenuBloc>().add(MenuEvent.openPage(GridPageContext(view)));
    };
  }
}
