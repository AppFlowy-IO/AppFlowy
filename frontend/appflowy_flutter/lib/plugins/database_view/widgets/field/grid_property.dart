import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/header/field_editor.dart';

class DatabasePropertyList extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;

  const DatabasePropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

  @override
  State<StatefulWidget> createState() => _DatabasePropertyListState();
}

class _DatabasePropertyListState extends State<DatabasePropertyList> {
  final PopoverMutex _popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DatabasePropertyBloc>(
        param1: widget.viewId,
        param2: widget.fieldController,
      )..add(const DatabasePropertyEvent.initial()),
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          final cells = state.fieldContexts.map((field) {
            return _GridPropertyCell(
              key: ValueKey(field.id),
              viewId: widget.viewId,
              fieldInfo: field,
              popoverMutex: _popoverMutex,
            );
          }).toList();

          return ReorderableColumn(
            needsLongPressDraggable: false,
            buildDraggableFeedback: (context, constraints, child) =>
                ConstrainedBox(
              constraints: constraints,
              child: Material(color: Colors.transparent, child: child),
            ),
            onReorder: (from, to) => context.read<DatabasePropertyBloc>().add(
                  DatabasePropertyEvent.moveField(
                    fieldId: cells[from].fieldInfo.id,
                    fromIndex: from,
                    toIndex: to,
                  ),
                ),
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            children: cells,
          );
        },
      ),
    );
  }
}

class _GridPropertyCell extends StatefulWidget {
  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;

  const _GridPropertyCell({
    super.key,
    required this.fieldInfo,
    required this.viewId,
    required this.popoverMutex,
  });

  @override
  State<_GridPropertyCell> createState() => _GridPropertyCellState();
}

class _GridPropertyCellState extends State<_GridPropertyCell> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final checkmark = svgWidget(
      widget.fieldInfo.visibility ? 'home/show' : 'home/hide',
      color: Theme.of(context).iconTheme.color,
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: _editFieldButton(context, checkmark),
    );
  }

  Widget _editFieldButton(BuildContext context, Widget checkmark) {
    return AppFlowyPopover(
      mutex: widget.popoverMutex,
      controller: _popoverController,
      offset: const Offset(8, 0),
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(240, 400)),
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          widget.fieldInfo.name,
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: svgWidget(
          widget.fieldInfo.fieldType.iconName(),
          color: Theme.of(context).iconTheme.color,
        ),
        rightIcon: FlowyIconButton(
          hoverColor: Colors.transparent,
          onPressed: () {
            context.read<DatabasePropertyBloc>().add(
                  DatabasePropertyEvent.setFieldVisibility(
                    widget.fieldInfo.id,
                    !widget.fieldInfo.visibility,
                  ),
                );
          },
          icon: checkmark.padding(all: 6.0),
        ),
        onTap: () => _popoverController.show(),
      ).padding(horizontal: 6.0),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: widget.fieldInfo.field,
          ),
        );
      },
    );
  }
}
