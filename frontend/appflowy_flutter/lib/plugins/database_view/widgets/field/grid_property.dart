import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

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
          final cells = state.fields.map((field) {
            return GridPropertyCell(
              key: ValueKey(field.id),
              fieldController: widget.fieldController,
              viewId: widget.viewId,
              field: field,
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
                    fieldId: cells[from].field.id,
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

@visibleForTesting
class GridPropertyCell extends StatefulWidget {
  final FieldPB field;
  final String viewId;
  final PopoverMutex popoverMutex;
  final FieldController fieldController;

  const GridPropertyCell({
    super.key,
    required this.field,
    required this.viewId,
    required this.popoverMutex,
    required this.fieldController,
  });

  @override
  State<GridPropertyCell> createState() => _GridPropertyCellState();
}

class _GridPropertyCellState extends State<GridPropertyCell> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final visiblity = widget.field.visibility;
    final visibleIcon = FlowySvg(
      visiblity != FieldVisibility.AlwaysHidden
          ? FlowySvgs.show_m
          : FlowySvgs.hide_m,
      color: Theme.of(context).iconTheme.color,
    );

    return AppFlowyPopover(
      mutex: widget.popoverMutex,
      controller: _popoverController,
      offset: const Offset(8, 0),
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(240, 400)),
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText.medium(
            widget.field.name,
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIcon: FlowySvg(
            widget.field.fieldType.icon(),
            color: Theme.of(context).iconTheme.color,
          ),
          rightIcon: FlowyIconButton(
            hoverColor: Colors.transparent,
            onPressed: () {
              final newVisiblity = _newFieldVisibility(widget.field.visibility);
              context.read<DatabasePropertyBloc>().add(
                    DatabasePropertyEvent.setFieldVisibility(
                      widget.field.id,
                      newVisiblity,
                    ),
                  );
            },
            icon: visibleIcon.padding(all: 4.0),
          ),
          onTap: () => _popoverController.show(),
        ).padding(horizontal: 6.0),
      ),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          fieldId: widget.field.id,
          fieldController: widget.fieldController,
        );
      },
    );
  }

  FieldVisibility _newFieldVisibility(FieldVisibility current) {
    return switch (current) {
      FieldVisibility.AlwaysShown => FieldVisibility.AlwaysHidden,
      FieldVisibility.AlwaysHidden => FieldVisibility.AlwaysShown,
      _ => FieldVisibility.AlwaysHidden,
    };
  }
}
