import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/plugins/grid/application/setting/group_bloc.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class GridGroupList extends StatelessWidget {
  final String viewId;
  final GridFieldController fieldController;
  const GridGroupList({
    required this.viewId,
    required this.fieldController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GridGroupBloc(
        viewId: viewId,
        fieldController: fieldController,
      )..add(const GridGroupEvent.initial()),
      child: BlocBuilder<GridGroupBloc, GridGroupState>(
        builder: (context, state) {
          final cells = state.fieldContexts.map((field) {
            return _GridGroupCell(
              fieldContext: field,
              key: ValueKey(field.id),
            );
          }).toList();

          return ListView.separated(
            shrinkWrap: true,
            itemCount: cells.length,
            itemBuilder: (BuildContext context, int index) {
              return cells[index];
            },
            separatorBuilder: (BuildContext context, int index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
          );
        },
      ),
    );
  }

  void show(BuildContext context) {}
}

class _GridGroupCell extends StatelessWidget {
  final GridFieldContext fieldContext;
  const _GridGroupCell({required this.fieldContext, Key? key})
      : super(key: key);

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
      text: FlowyText.medium(fieldContext.name, fontSize: 12),
      hoverColor: theme.hover,
      leftIcon:
          svgWidget(fieldContext.fieldType.iconName(), color: theme.iconColor),
      onTap: () {},
    );
  }
}
