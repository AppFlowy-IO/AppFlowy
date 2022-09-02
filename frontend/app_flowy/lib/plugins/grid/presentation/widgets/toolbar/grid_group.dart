import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GridGroupList extends StatelessWidget {
  final String viewId;
  final GridFieldCache fieldCache;
  const GridGroupList({
    required this.viewId,
    required this.fieldCache,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  void show(BuildContext context) {}
}

class _GridGroupCell extends StatelessWidget {
  final FieldPB field;
  const _GridGroupCell({required this.field, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    // final checkmark = field.visibility
    //     ? svgWidget('home/show', color: theme.iconColor)
    //     : svgWidget('home/hide', color: theme.iconColor);

    // Padding(
    //                   padding: const EdgeInsets.only(right: 6),
    //                   child: svgWidget("grid/checkmark"),
    //                 ),

    return FlowyButton(
      text: FlowyText.medium(field.name, fontSize: 12),
      hoverColor: theme.hover,
      leftIcon: svgWidget(field.fieldType.iconName(), color: theme.iconColor),
      onTap: () {},
    );
  }
}
