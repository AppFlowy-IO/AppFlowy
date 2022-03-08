import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'constants.dart';

class HeaderCell extends StatelessWidget {
  final Field field;
  const HeaderCell(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: FlowyText.medium(field.name),
      hoverColor: theme.hover,
      onTap: () {},
    );
    // return Text(
    //   field.name,
    //   style: const TextStyle(fontSize: 15.0, color: Colors.black),
    // );
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
      padding: EdgeInsets.symmetric(vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
      child: child,
    );
  }
}

class HeaderCellLeading extends StatelessWidget {
  const HeaderCellLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GridSize.startHeaderPadding,
    );
  }
}
