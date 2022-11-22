import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/plugins/grid/application/setting/group_bloc.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class GridGroupList extends StatelessWidget {
  final String viewId;
  final GridFieldController fieldController;
  final VoidCallback onDismissed;
  const GridGroupList({
    required this.viewId,
    required this.fieldController,
    required this.onDismissed,
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
          final cells = state.fieldContexts.map((fieldInfo) {
            Widget cell = _GridGroupCell(
              fieldInfo: fieldInfo,
              onSelected: () => onDismissed(),
              key: ValueKey(fieldInfo.id),
            );

            if (!fieldInfo.canGroup) {
              cell = IgnorePointer(child: Opacity(opacity: 0.3, child: cell));
            }
            return cell;
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
}

class _GridGroupCell extends StatelessWidget {
  final VoidCallback onSelected;
  final FieldInfo fieldInfo;
  const _GridGroupCell({
    required this.fieldInfo,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? rightIcon;
    if (fieldInfo.isGroupField) {
      rightIcon = Padding(
        padding: const EdgeInsets.all(2.0),
        child: svgWidget("grid/checkmark"),
      );
    }

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(fieldInfo.name, fontSize: 12),
        leftIcon: svgWidget(
          fieldInfo.fieldType.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
        rightIcon: rightIcon,
        onTap: () {
          context.read<GridGroupBloc>().add(
                GridGroupEvent.setGroupByField(
                  fieldInfo.id,
                  fieldInfo.fieldType,
                ),
              );
          onSelected();
        },
      ),
    );
  }
}
