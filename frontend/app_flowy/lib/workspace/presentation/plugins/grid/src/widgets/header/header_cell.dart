import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_editor.dart';

class HeaderCell extends StatelessWidget {
  final Field field;
  const HeaderCell(this.field, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final button = FlowyButton(
      hoverColor: theme.hover,
      onTap: () => FieldEditor.show(context, field),
      rightIcon: svg("editor/details", color: theme.iconColor),
      text: Padding(padding: GridSize.cellContentInsets, child: FlowyText.medium(field.name, fontSize: 12)),
    );

    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    final decoration = BoxDecoration(border: Border(top: borderSide, right: borderSide, bottom: borderSide));

    return Container(
      width: field.width.toDouble(),
      decoration: decoration,
      padding: GridSize.headerContentInsets,
      child: button,
    );
  }
}
