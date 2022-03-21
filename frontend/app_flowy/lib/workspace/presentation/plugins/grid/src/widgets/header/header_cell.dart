import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_window.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HeaderCell extends StatelessWidget {
  final Field field;
  const HeaderCell(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: Padding(padding: GridSize.cellContentInsets, child: FlowyText.medium(field.name, fontSize: 12)),
      hoverColor: theme.hover,
      onTap: () {
        FlowyPoppuWindow.show(
          context,
          size: Size(300, 100),
          child: CusTextField(),
        );

        // StyledDialog(
        //   child: SingleChildScrollView(
        //     child: Container(
        //       color: Colors.red,
        //       child: TextField(),
        //     ),
        //   ),
        // ).show(context);
      },
      rightIcon: svg("editor/details", color: theme.iconColor),
    );
  }
}

class CusTextField extends StatelessWidget {
  const CusTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
        color: theme.bg3,
        child: TextField(
          decoration: InputDecoration(hintText: 'Please enter a text'),
          onSubmitted: print,
        ));
  }
}

class HeaderCellContainer extends StatelessWidget {
  final HeaderCell child;
  final double width;
  const HeaderCellContainer({Key? key, required this.child, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(top: borderSide, right: borderSide, bottom: borderSide),
      ),
      padding: GridSize.headerContentInsets,
      child: child,
    );
  }
}
