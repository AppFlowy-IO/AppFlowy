import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class GridGroupList extends StatelessWidget {
  final String viewId;
  final FieldController fieldController;
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
      create: (context) => DatabaseGroupBloc(
        viewId: viewId,
        fieldController: fieldController,
      )..add(const DatabaseGroupEvent.initial()),
      child: BlocBuilder<DatabaseGroupBloc, DatabaseGroupState>(
        builder: (context, state) {
          final cells = state.fieldContexts.map((fieldInfo) {
            Widget cell = _GridGroupCell(
              fieldInfo: fieldInfo,
              onSelected: () => onDismissed(),
              key: ValueKey(fieldInfo.id),
            );

            if (!fieldInfo.canBeGroup) {
              cell = IgnorePointer(child: Opacity(opacity: 0.3, child: cell));
            }
            return cell;
          }).toList();

          return ListView.separated(
            shrinkWrap: true,
            itemCount: cells.length,
            itemBuilder: (BuildContext context, int index) => cells[index],
            separatorBuilder: (BuildContext context, int index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            padding: const EdgeInsets.all(6.0),
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
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(fieldInfo.name),
        leftIcon: svgWidget(
          fieldInfo.fieldType.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
        rightIcon: rightIcon,
        onTap: () {
          context.read<DatabaseGroupBloc>().add(
                DatabaseGroupEvent.setGroupByField(
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
